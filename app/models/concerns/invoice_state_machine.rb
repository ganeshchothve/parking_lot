module InvoiceStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :tentative, initial: true
      state :draft, :raised, :pending_approval
      state :approved, :rejected, :tax_invoice_raised
      state :paid

      event :draft do
        transitions from: :tentative, to: :draft, success: %i[after_raised]
        transitions from: :rejected, to: :draft
      end

      event :raise do
        transitions from: :draft, to: :raised, if: :can_raise?, success: %i[after_raised]
        transitions from: :rejected, to: :raised, success: %i[after_re_raised]
      end

      event :pending_approval, after: :send_notification do
        transitions from: :raised, to: :pending_approval #, success: %i[after_pending_approval]
      end

      event :approve, after: [:make_payment, :send_notification] do
        transitions from: :raised, to: :approved
        transitions from: :pending_approval, to: :approved, success: %i[after_approved]
      end

      event :reject, after: :send_notification do
        transitions from: :raised, to: :rejected, success: %i[after_rejected]
        transitions from: :pending_approval, to: :rejected, success: %i[after_rejected]
        transitions from: :tentative, to: :rejected
        transitions from: :draft, to: :rejected
      end

      event :tax_invoice_raise do
        transitions from: :approved, to: :tax_invoice_raised
      end

      event :paid, after: :mark_invoiceable_paid do
        transitions from: :tax_invoice_raised, to: :paid
        transitions from: :approved, to: :paid
      end
    end

    def can_raise?
      self.draft?
    end

    def get_pending_approval_recipients_list
      recipients = []
      #User.where(role: 'billing_team').each do |user|
      #  recipients << user
      #end
      recipients << self.manager.manager.manager if self.manager.try(:manager).try(:manager).present?
      recipients
    end

    def get_approved_recipients_list
      recipients = []
      recipients << self.manager if self.manager.present?
      recipients << self.manager.manager if self.manager.try(:manager).present?
      recipients << self.manager.manager.manager if self.manager.try(:manager).try(:manager).present?
      recipients
    end

    def get_paid_recipients_list
      get_approved_recipients_list
    end

    def get_rejected_recipients_list
      recipients = []
      recipients << self.manager if self.manager.present?
      recipients
    end

    def send_notification
      recipients = self.send("get_#{status}_recipients_list")
      if recipients.present? && project.booking_portal_client.email_enabled?
        template_name = "invoice_#{status}"
        if email_template = Template::EmailTemplate.where(name: template_name, project_id: project_id).first
          email = Email.new(
            booking_portal_client_id: project.booking_portal_client_id,
            email_template_id: email_template.id,
            cc: [],
            recipients: recipients,
            cc_recipients: [],
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
          email.sent! if email.save
        end
      end
      if recipients.pluck(:phone).present? && project.booking_portal_client.sms_enabled?
        if sms_template = Template::SmsTemplate.where(name: template_name, project_id: project_id).first
          recipients.each do |recipient|
            Sms.create(
              booking_portal_client_id: project.booking_portal_client_id,
              recipient_id: recipient.id,
              sms_template_id: sms_template.id,
              triggered_by_id: self.id,
              triggered_by_type: self.class.to_s
            ) if recipient.phone.present?
          end
        end
      end
    end

    def after_raised
      unless category == "brokerage"
        self.raised_date = Time.now if aasm.to_state.to_s == "draft"
      else
        self.raised_date = Time.now if aasm.to_state.to_s == "raised"
      end
      # self.generate_pdf
    end

    def after_approved
      self.processing_date = Time.now
      self.approved_date = Time.now
      reject_pending_deductions
    end

    def after_rejected
      self.processing_date = Time.now
      #self.net_amount = 0
      reject_pending_deductions
    end

    def after_re_raised
      self.incentive_deduction.pending_approval! if self.incentive_deduction? && self.incentive_deduction.rejected?
    end

    def reject_pending_deductions
      self.incentive_deduction.rejected! if self.incentive_deduction? && self.incentive_deduction.pending_approval?
    end

    def make_payment
      if self.brokerage_type == 'sub_brokerage'
        if self.category.in?(%w(walk_in spot_booking))
          if Rails.env.staging? || Rails.env.production?
            InvoicePayoutWorker.perform_async(self.id.to_s)
          else
            InvoicePayoutWorker.new.perform(self.id.to_s)
          end
        end
      end
    end

    def mark_invoiceable_paid
      case category
      when 'walk_in'
        if invoiceable.is_a?(SiteVisit) && invoiceable.may_paid?
          invoiceable.aasm(:status).fire!(:paid)
        end
      end
    end

    def move_manual_invoice_to_draft
      if self.tentative? && self._type == "Invoice::Manual"
        self.draft!
      end
    end

    def change_status(event)
      begin
        if self.respond_to?("may_#{event}?") && self.send("may_#{event}?") && self._type == "Invoice::Calculated" && invoiceable.find_incentive_schemes(self.category).present?
          self.assign_attributes(rejection_reason: "#{invoiceable.class.try(:model_name).try(:human)} has been cancelled") if event == "reject"
          self.aasm.fire(event.to_sym)

          unless self.save
            Rails.logger.error "[InvoiceStateMachine][#{__method__}][ERR] id-#{id.to_s}, event-#{event} Errors: #{self.errors.full_messages.join(',')}"
          end
        end
      rescue StandardError => e
        Rails.logger.error "[InvoiceStateMachine][#{__method__}][ERR] id-#{id.to_s}, event-#{event} Errors: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
      end
    end

  end
end
