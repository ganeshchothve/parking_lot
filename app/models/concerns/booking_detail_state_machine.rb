module BookingDetailStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status, whiny_transitions: false do
      # state :filter, initial: true
      # state :tower, :project_unit, :user_kyc

      state :hold, initial: true
      state :blocked, :booked_tentative, :booked_confirmed, :under_negotiation, :scheme_rejected, :scheme_approved
      state :swap_requested, :swapping, :swapped, :swap_rejected
      state :cancellation_requested, :cancelling, :cancelled, :cancellation_rejected

      # event :filter do
      #   transitions from: :filter, to: :filter
      # end

      # event :tower do
      #   transitions from: :tower, to: :tower
      #   transitions from: :filter, to: :tower
      # end

      # event :project_unit do
      #   transitions from: :project_unit, to: :project_unit
      #   transitions from: :tower, to: :project_unit
      # end

      # event :user_kyc do
      #   transitions from: :user_kyc, to: :user_kyc
      #   transitions from: :project_unit, to: :user_kyc
      # end

      event :hold, after: :after_hold_event do
        transitions from: :hold, to: :hold
        # transitions from: :user_kyc, to: :hold
      end

      event :under_negotiation, after: %i[after_under_negotiation_event] do
        transitions from: :under_negotiation, to: :under_negotiation
        transitions from: :hold, to: :under_negotiation
        transitions from: :scheme_approved, to: :under_negotiation
        transitions from: :blocked, to: :under_negotiation
        transitions from: :booked_tentative, to: :under_negotiation
        transitions from: :booked_confirmed, to: :under_negotiation
        transitions from: :scheme_rejected, to: :under_negotiation
      end

      event :scheme_approved, after: %i[after_scheme_approved_event  update_selldo!] do
        transitions from: :scheme_approved, to: :scheme_approved
        transitions from: :under_negotiation, to: :scheme_approved
        transitions from: :scheme_rejected, to: :scheme_approved
      end

      event :scheme_rejected, after: %i[after_scheme_rejected_event  update_selldo!] do
        transitions from: :scheme_rejected, to: :scheme_rejected
        transitions from: :under_negotiation, to: :scheme_rejected
      end

      event :blocked, after: %i[after_blocked_event update_selldo!] do
        transitions from: :blocked, to: :blocked
        transitions from: :hold, to: :blocked
        transitions from: :scheme_approved, to: :blocked
        transitions from: :swap_rejected, to: :blocked
        transitions from: :cancellation_rejected, to: :blocked
      end

      event :booked_tentative, after: %i[send_notification after_booked_tentative_event update_selldo!] do
        transitions from: :booked_tentative, to: :booked_tentative
        transitions from: :blocked, to: :booked_tentative, success: :sync_booking
      end

      event :booked_confirmed, after: %i[send_notification after_booked_confirmed_event update_selldo!] do
        transitions from: :booked_confirmed, to: :booked_confirmed
        transitions from: :booked_tentative, to: :booked_confirmed , success: :sync_booking
      end

      event :swap_requested do
        transitions from: :swap_requested, to: :swap_requested
        transitions from: :blocked, to: :swap_requested
        transitions from: :booked_tentative, to: :swap_requested
        transitions from: :booked_confirmed, to: :swap_requested
      end

      event :swapping do
        transitions from: :swapping, to: :swapping
        transitions from: :swap_requested, to: :swapping
      end

      event :swapped, after: %i[trigger_workflow] do
        transitions from: :swapped, to: :swapped
        transitions from: :swapping, to: :swapped, after: :update_user_request_to_resolved
      end

      event :swap_rejected, after: [:update_booking_detail_to_blocked, :trigger_workflow] do
        transitions from: :swap_rejected, to: :swap_rejected
        transitions from: :swap_requested, to: :swap_rejected
        transitions from: :swapping, to: :swap_rejected, after: :update_user_request_to_rejected
      end

      event :cancellation_requested do
        transitions from: :cancellation_requested, to: :cancellation_requested
        transitions from: :blocked, to: :cancellation_requested
        transitions from: :booked_tentative, to: :cancellation_requested
        transitions from: :booked_confirmed, to: :cancellation_requested
        transitions from: :scheme_approved, to: :cancellation_requested
      end

      event :cancellation_rejected, after: [:update_booking_detail_to_blocked, :trigger_workflow] do
        transitions from: :cancelling, to: :cancellation_rejected, after: :update_user_request_to_rejected
        transitions from: :cancellation_requested, to: :cancellation_rejected
      end

      event :cancelling do
        transitions from: :cancelling, to: :cancelling
        transitions from: :cancellation_requested, to: :cancelling
      end

      event :cancel, after: %i[release_project_unit! trigger_workflow] do
        transitions from: :booked_tentative, to: :cancelled
        transitions from: :blocked, to: :cancelled
        transitions from: :cancelled, to: :cancelled
        transitions from: :scheme_rejected, to: :cancelled
        transitions from: :cancelling, to: :cancelled, after: :update_user_request_to_resolved, success: :sync_booking
      end
    end

    def update_user_request_to_rejected
      user_requests.processing.first.try(:rejected!)
    end

    def update_user_request_to_resolved
      current_user_request = user_requests.in(status: ['processing']).first
      current_user_request.resolved!
      release_project_unit! if current_user_request.is_a?(UserRequest::Swap)
    end

    def update_booking_detail_to_blocked
      blocked!
    end

    # This method push booking portal to next state as scheme approved.
    # For this booking detail should be in under_negotiation
    # If booking detail scheme is approved the booking detail in scheme_approved
    # If booking detail scheme is rejected then booking detail must be in scheme rejected
    # If booking detail scheme is draft then booking detail stay in under_negotiation
    # Setting date on which the project_unit is blocked and on which date it should be released i.e. after blocking_days from the day project_unit is blocked
    def after_under_negotiation_event
      create_default_scheme
      _project_unit = project_unit
      _project_unit.assign_attributes(status: 'blocked', held_on: nil, blocked_on: Date.today, auto_release_on: ( Date.today + _project_unit.blocking_days.days) )
      _project_unit.save
      self.set(booked_on: _project_unit.blocked_on)
      trigger_workflow
      if under_negotiation? && booking_detail_scheme.approved?
        scheme_approved!
      else
        # auto_released_extended_inform_buyer!
        # elsif !booking_detail_scheme.present? && (booking_detail_schemes.distinct(:status).include? 'rejected')
        #   scheme_rejected!
      end
    end

    def after_scheme_approved_event
      trigger_workflow
      if scheme_approved? && get_paid_amount >= project_unit.blocking_amount
        blocked!
      end
    end

    def after_scheme_rejected_event
      trigger_workflow
      receipts.each do |receipt|
        receipt.booking_detail_id = nil
        receipt.save
      end
    end
    # Updating blocked date of project_unit to today and  auto_release_on will be changed to blocking_days more from current auto_release_on.
    def after_blocked_event
      _lead = lead
      _lead.booking_done!
      _project_unit = project_unit
      _project_unit.blocked_on = Date.today
      if self.agreement_date.blank? && self.project_unit.present?
        self.set(agreement_date: Date.today + 45)
        self.set(tentative_agreement_date: Date.today + 45)
      end
      _project_unit.auto_release_on ||= Date.today
      _project_unit.auto_release_on +=  _project_unit.blocking_days.days
      _project_unit.save
      self.set(booked_on: _project_unit.blocked_on)

      trigger_workflow

      if blocked? && get_paid_amount > project_unit.blocking_amount
        booked_tentative!
      # else
        # auto_released_extended_inform_buyer!
        send_email_and_sms_as_booked if project_unit.present?
      end
    end
    # Updating blocked date of project_unit to today and  auto_release_on will be changed to blocking_days more from current auto_release_on.
    def after_booked_tentative_event
      trigger_workflow
      if project_unit.present?
        if booked_tentative? && (get_paid_amount >= self.get_booking_price)
          booked_confirmed!
        else
          send_email_and_sms_as_booked
        end
      end
    end

    #
    # Dummy Methods This is last step of application.
    #
    #
    # Updating blocked date of project_unit to today and  auto_release_on to nil as booking is confirmed.
    def after_booked_confirmed_event
      if project_unit.present?
        _project_unit = project_unit
        _project_unit.auto_release_on = nil
        _project_unit.save
        send_email_and_sms_as_confirmed
      end
      # create asset and send to zoho sign
      if (self.aasm.from_state == :booked_tentative && self.user.booking_portal_client.document_sign.present?)
        # self.send_booking_form_to_sign
      end
      trigger_workflow
    end

    #
    # This function call after hold event.
    # In this, booking detail move to next stage when its current state is hold and paid ammount is greater than zero.
    #
    # @return [<type>] <description>
    #
    def after_hold_event
      trigger_workflow
      under_negotiation! if hold? && (get_paid_amount > 0)
    end

    #
    # This function return the total paid amount.
    # In this we conside only success and clearance_pending receipts
    #
    # @return [Integer]
    #
    def get_paid_amount
      receipts.in(status: %w[success clearance_pending]).sum(:total_amount)
    end

    #
    # This function create booking details scheme when its empty.
    # This create new booking details related scheme which copy of associated project unit's tower default scheme. with same status.
    #
    def create_default_scheme
      if booking_detail_scheme.blank?
        unless lead.manager_role?('channel_partner')
          scheme = project_unit.project_tower.default_scheme
        else
          filters = {fltrs: { can_be_applied_by_role: lead.manager_role, project_tower: project_unit.project_tower_id, user_role: lead.user_role, user_id: lead.user_id, status: 'approved', default_for_user_id: lead.manager_id } }
          scheme = Scheme.build_criteria(filters).first
        end
        BookingDetailScheme.create(
          derived_from_scheme_id: scheme.id,
          booking_detail_id: id,
          created_by_id: lead.user_id,
          booking_portal_client_id: scheme.booking_portal_client_id,
          cost_sheet_template_id: scheme.cost_sheet_template_id,
          payment_schedule_template_id: scheme.payment_schedule_template_id,
          project_unit_id: project_unit_id,
          status: scheme.status
        ) if scheme
      else
        true
      end
    end
    # This method is called after booked_confirmed event
    # In this send email and sms to the user about confirmation of booking
    def send_email_and_sms_as_confirmed
      if self.project_unit.booking_portal_client.email_enabled?
        attachments_attributes = []
        allotment_letter = project_unit.booking_portal_client.templates.where(_type: "Template::AllotmentLetterTemplate", project_id: self.project_id, booking_portal_client_id: self.booking_portal_client_id).first
        if allotment_letter.present?
          action_mailer_email = ApplicationMailer.test(body: project_unit.booking_portal_client.templates.where(_type: "Template::AllotmentLetterTemplate", project_id: self.project_id, booking_portal_client_id: self.booking_portal_client_id).first.parsed_content(self))
          pdf = WickedPdf.new.pdf_from_string(action_mailer_email.html_part.body.to_s)
          File.open("#{Rails.root}/exports/allotment_letter-#{project_unit.name}.pdf", "wb") do |file|
            file << pdf
          end
          attachments_attributes << {file: File.open("#{Rails.root}/exports/allotment_letter-#{project_unit.name}.pdf")}
        end
        email = Email.create!({
            project_id: project_id,
            booking_portal_client_id: project_unit.booking_portal_client_id,
            email_template_id: Template::EmailTemplate.where(name: "booking_confirmed", project_id: project_id, booking_portal_client_id: project_unit.booking_portal_client_id).first.try(:id),
            cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
            recipients: [lead.user],
            cc_recipients: (lead.manager_id.present? ? [lead.manager] : []),
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s,
            attachments_attributes: attachments_attributes
          })
        email.sent!
      end
      if self.project_unit.booking_portal_client.sms_enabled?
        Sms.create!(
              project_id: project_id,
              booking_portal_client_id: user.booking_portal_client_id,
              recipient_id: lead.user_id,
              sms_template_id: Template::SmsTemplate.where(project_id: project_id, name: "booking_confirmed", booking_portal_client_id: user.booking_portal_client_id).first.try(:id),
              triggered_by_id: self.id,
              triggered_by_type: self.class.to_s
            )
      end

      template = Template::NotificationTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: "booking_confirmed").first
      if template.present? && template.is_active? && user.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          recipient_id: self.user.id,
          booking_portal_client_id: self.user.booking_portal_client.id
        )
        push_notification.save
      end
    end

    # This method is called after of blocked and booked_tentative event
    # In this send email and sms to the user when the booking is in one of the booking stage
    def send_email_and_sms_as_booked
      if project_unit.booking_portal_client.email_enabled?
        attachments_attributes = []
        _status = status.sub('booked_', '')
        email = Email.new(
          project_id: project_id,
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.where(name: "booking_#{_status}", project_id: project_id, booking_portal_client_id: project_unit.booking_portal_client_id).first.try(:id),
          cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
          recipients: [lead.user],
          cc_recipients: (lead.manager_id.present? ? [lead.manager] : []),
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          attachments_attributes: attachments_attributes
        )
        email.sent! if email.save
      end
      if project_unit.booking_portal_client.sms_enabled?
        Sms.create(
            project_id: project_id,
            booking_portal_client_id: project_unit.booking_portal_client_id,
            recipient_id: lead.user_id,
            sms_template_id: Template::SmsTemplate.where(project_id: project_id, name: "booking_blocked", booking_portal_client_id: project_unit.booking_portal_client_id).first.try(:id),
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
      end
    end

    def send_notification
      recipient = self.manager || self.lead.manager
      template = Template::NotificationTemplate.where(name: get_notification_template_status, booking_portal_client_id: self.booking_portal_client_id).first
      if template.present? && template.is_active? && user.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          recipient_id: recipient.id,
          booking_portal_client_id: self.user.booking_portal_client.id
        )
        push_notification.save
      end
    end

    def get_notification_template_status
      case status
      when "blocked"
        "booking_blocked"
      when "booked_tentative"
        "booking_tentative"
      when "booked_confirmed"
        "booking_confirmed"
      end
    end

    #
    # This method release the project Unit. Without any fields validation.
    #
    def release_project_unit!
      return unless self.project_unit.present?
      project_unit.make_available
      project_unit.save(validate: false)
      SelldoLeadUpdater.perform_async(lead_id.to_s, {stage: 'cancelled'})
      if self.booking_portal_client.kylas_tenant_id.present?
        #trigger all workflow events in Kylas
        if Rails.env.production?
          Kylas::TriggerWorkflowEventsWorker.perform_async(self.id.to_s, self.class.to_s)
        else
          Kylas::TriggerWorkflowEventsWorker.new.perform(self.id.to_s, self.class.to_s)
        end
      end
    end

    def update_selldo!
      SelldoLeadUpdater.perform_async(lead_id.to_s, {stage: status})
      SelldoLeadUpdater.perform_async(lead_id.to_s, {action: 'add_slot_details', slot_status: 'booked'})
    end

    def move_to_next_state!(status)
      if self.respond_to?("may_#{status}?") && self.send("may_#{status}?")
        self.aasm.fire!(status.to_sym)
      else
        self.errors.add(:base, 'Invalid transition')
      end
      self.errors.empty?
    end

    def sync_booking
      crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url), booking_portal_client_id: self.booking_portal_client_id).first
      if crm_base.present?
        api, api_log = self.push_in_crm(crm_base)
      end
    end

    def selldo_booking_status
      I18n.t("mongoid.attributes.booking_detail/selldo_status.#{status}")
    end

    def trigger_workflow
      # trigger all workflow events in Kylas
      if self.booking_portal_client.kylas_tenant_id.present?
        if Rails.env.production?
          Kylas::TriggerWorkflowEventsWorker.perform_async(self.id.to_s, self.class.to_s)
        else
          Kylas::TriggerWorkflowEventsWorker.new.perform(self.id.to_s, self.class.to_s)
        end
      end
    end

  end
end
