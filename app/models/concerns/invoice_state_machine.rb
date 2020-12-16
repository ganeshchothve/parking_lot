module InvoiceStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :pending_approval
      state :approved, :rejected

      event :raise, after: %w(after_raise_event send_notification) do
        transitions from: :draft, to: :pending_approval
      end

      event :re_raise, after: :send_notification do
        transitions from: :rejected, to: :pending_approval, success: %i[after_re_raised]
      end

      event :approve, after: :send_notification do
        transitions from: :pending_approval, to: :approved, success: %i[after_approved]
      end

      event :reject do
        transitions from: :pending_approval, to: :rejected, success: :after_rejected
      end
    end

    def get_pending_approval_recipients_list
      recipients = []
      User.where(role: 'billing_team').each do |user|
        recipients << user
      end
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

    def send_notification
      recipients = self.send("get_#{status}_recipients_list")
      if recipients.present? && incentive_scheme.booking_portal_client.email_enabled?
        template_name = "invoice_#{status}"
        if email_template = Template::EmailTemplate.where(name: template_name, project_id: project_id).first
          email = Email.create!(
            booking_portal_client_id: incentive_scheme.booking_portal_client_id,
            email_template_id: email_template.id,
            cc: [],
            recipients: recipients,
            cc_recipients: [],
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
          email.sent!
        end
      end
      if recipients.pluck(:phone).present? && incentive_scheme.booking_portal_client.sms_enabled?
        if sms_template = Template::SmsTemplate.where(name: template_name, project_id: project_id).first
          recipients.each do |recipient|
            Sms.create!(
              booking_portal_client_id: incentive_scheme.booking_portal_client_id,
              recipient_id: recipient.id,
              sms_template_id: sms_template.id,
              triggered_by_id: self.id,
              triggered_by_type: self.class.to_s
            ) if recipient.phone.present?
          end
        end
      end
    end

    def after_raise_event
      self.raised_date = Time.now
    end

    def after_approved
      self.processing_date = Time.now
      self.approved_date = Time.now
      reject_pending_deductions
    end

    def after_rejected
      self.processing_date = Time.now
      self.net_amount = 0
      reject_pending_deductions
    end

    def after_re_raised
      self.incentive_deduction.pending_approval! if self.incentive_deduction? && self.incentive_deduction.rejected?
    end

    def reject_pending_deductions
      self.incentive_deduction.rejected! if self.incentive_deduction? && self.incentive_deduction.pending_approval?
    end

    before_validation do |invoice|
      _event = invoice.event.to_s
      invoice.event = nil
      if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s)
        if invoice.send("may_#{_event.to_s}?")
          invoice.aasm.fire(_event.to_sym)
          invoice.save
        else
          invoice.errors.add(:status, 'transition is invalid')
        end
      end
    end

  end
end
