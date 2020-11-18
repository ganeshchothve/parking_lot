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
        transitions from: :scheme_approved, to: :blocked
        transitions from: :swap_rejected, to: :blocked
        transitions from: :cancellation_rejected, to: :blocked
      end

      event :booked_tentative, after: %i[after_booked_tentative_event update_selldo!] do
        transitions from: :booked_tentative, to: :booked_tentative
        transitions from: :blocked, to: :booked_tentative
      end

      event :booked_confirmed, after: %i[after_booked_confirmed_event update_selldo!] do
        transitions from: :booked_confirmed, to: :booked_confirmed
        transitions from: :booked_tentative, to: :booked_confirmed
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

      event :swapped do
        transitions from: :swapped, to: :swapped
        transitions from: :swapping, to: :swapped, after: :update_user_request_to_resolved
      end

      event :swap_rejected, after: :update_booking_detail_to_blocked do
        transitions from: :swap_rejected, to: :swap_rejected
        transitions from: :swap_requested, to: :swap_rejected
        transitions from: :swapping, to: :swap_rejected, after: :update_user_request_to_rejected
      end

      event :cancellation_requested do
        transitions from: :cancellation_requested, to: :cancellation_requested
        transitions from: :blocked, to: :cancellation_requested
        transitions from: :booked_tentative, to: :cancellation_requested
        transitions from: :booked_confirmed, to: :cancellation_requested
      end

      event :cancellation_rejected, after: :update_booking_detail_to_blocked do
        transitions from: :cancelling, to: :cancellation_rejected, after: :update_user_request_to_rejected
        transitions from: :cancellation_requested, to: :cancellation_rejected
      end

      event :cancelling do
        transitions from: :cancelling, to: :cancelling
        transitions from: :cancellation_requested, to: :cancelling
      end

      event :cancel, after: :release_project_unit! do
        transitions from: :cancelled, to: :cancelled
        transitions from: :scheme_rejected, to: :cancelled
        transitions from: :cancelling, to: :cancelled, after: :update_user_request_to_resolved
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
      if under_negotiation? && booking_detail_scheme.approved?
        scheme_approved!
      else
        # auto_released_extended_inform_buyer!
        # elsif !booking_detail_scheme.present? && (booking_detail_schemes.distinct(:status).include? 'rejected')
        #   scheme_rejected!
      end
    end

    def after_scheme_approved_event
      if scheme_approved? && get_paid_amount >= project_unit.blocking_amount
        blocked!
      end
    end

    def after_scheme_rejected_event
      receipts.each do |receipt|
        receipt.booking_detail_id = nil
        receipt.save
      end
     end
    # Updating blocked date of project_unit to today and  auto_release_on will be changed to blocking_days more from current auto_release_on.
    def after_blocked_event
      _project_unit = project_unit
      _project_unit.blocked_on = Date.today
      _project_unit.auto_release_on ||= Date.today
      _project_unit.auto_release_on +=  _project_unit.blocking_days.days
      _project_unit.save
      if blocked? && get_paid_amount > project_unit.blocking_amount
        booked_tentative!
      else
        auto_released_extended_inform_buyer!
        send_email_and_sms_as_booked
      end
    end
    # Updating blocked date of project_unit to today and  auto_release_on will be changed to blocking_days more from current auto_release_on.
    def after_booked_tentative_event
      if booked_tentative? && (get_paid_amount >= project_unit.booking_price)
        booked_confirmed!
      else
        send_email_and_sms_as_booked
      end
    end

    #
    # Dummy Methods This is last step of application.
    #
    #
    # Updating blocked date of project_unit to today and  auto_release_on to nil as booking is confirmed.
    def after_booked_confirmed_event
      _project_unit = project_unit
      _project_unit.auto_release_on = nil
      _project_unit.save
      send_email_and_sms_as_confirmed
      # create asset and send to zoho sign
      if self.aasm.from_state == :booked_tentative
        self.send_booking_form_to_sign
      end
    end

    #
    # This function call after hold event.
    # In this, booking detail move to next stage when its current state is hold and paid ammount is greater than zero.
    #
    # @return [<type>] <description>
    #
    def after_hold_event
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
        action_mailer_email = ApplicationMailer.test(body: project_unit.booking_portal_client.templates.where(_type: "Template::AllotmentLetterTemplate").first.parsed_content(self))
        pdf = WickedPdf.new.pdf_from_string(action_mailer_email.html_part.body.to_s)
        File.open("#{Rails.root}/exports/allotment_letter-#{project_unit.name}.pdf", "wb") do |file|
          file << pdf
        end
        attachments_attributes << {file: File.open("#{Rails.root}/exports/allotment_letter-#{project_unit.name}.pdf")}
        email = Email.create!({
            booking_portal_client_id: project_unit.booking_portal_client_id,
            email_template_id: Template::EmailTemplate.find_by(name: "booking_confirmed").id,
            cc: [project_unit.booking_portal_client.notification_email],
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
              booking_portal_client_id: user.booking_portal_client_id,
              recipient_id: lead.user_id,
              sms_template_id: Template::SmsTemplate.find_by(name: "booking_confirmed").id,
              triggered_by_id: self.id,
              triggered_by_type: self.class.to_s
            )
      end
    end

    # This method is called after of blocked and booked_tentative event
    # In this send email and sms to the user when the booking is in one of the booking stage
    def send_email_and_sms_as_booked
      if project_unit.booking_portal_client.email_enabled?
        attachments_attributes = []
        _status = status.sub('booked_', '')
        email = Email.create!(
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "booking_#{_status}").id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [lead.user],
          cc_recipients: (lead.manager_id.present? ? [lead.manager] : []),
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          attachments_attributes: attachments_attributes
        )
        email.sent!
      end
      if project_unit.booking_portal_client.sms_enabled?
        Sms.create!(
            booking_portal_client_id: project_unit.booking_portal_client_id,
            recipient_id: lead.user_id,
            sms_template_id: Template::SmsTemplate.find_by(name: "booking_blocked").id,
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
      end
    end

    #
    # This method release the project Unit. Without any fields validation.
    #
    def release_project_unit!
      project_unit.make_available
      project_unit.save(validate: false)
      SelldoLeadUpdater.perform_async(user_id, {stage: 'cancelled'})

    end

    def update_selldo!
      if project_unit && project_unit.booking_portal_client.selldo_api_key.present?
        SelldoLeadUpdater.perform_async(user_id, {stage: status})
      end
    end

  end
end
