module InvoiceStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :pending_approval
      state :approved, :rejected

      event :raise, after: %i[after_pending_approval_event send_notification] do
        transitions from: :draft, to: :pending_approval #, after: :send_notification
      end

      event :re_raise, after: %i[after_re_raise_event send_notification] do
        transitions from: :rejected, to: :pending_approval
      end

      event :approve, after: %i[after_approved_event send_notification] do
        transitions from: :pending_approval, to: :approved, if: :can_approve?
      end

      event :reject, after: :after_rejected_event do
        transitions from: :pending_approval, to: :rejected
      end
    end

    def get_pending_approval_recipients_list
      recipients = []
      User.where(role: 'billing_team').each do |user|
        recipients << user
      end
      recipients << booking_detail.lead.manager.manager.manager if booking_detail.lead.manager.try(:manager).try(:manager).present?
      recipients
    end

    def get_approved_recipients_list
      recipients = []
      recipients << booking_detail.lead.manager if booking_detail.lead.manager.present?
      recipients << booking_detail.lead.manager.manager if booking_detail.lead.manager.try(:manager).present?
      recipients << booking_detail.lead.manager.manager.manager if booking_detail.lead.manager.try(:manager).try(:manager).present?
      recipients
    end

    def send_notification
      recipients = self.send("get_#{status}_recipients_list")
      if recipients.present? && booking_detail.project_unit.booking_portal_client.email_enabled?
        template_name = "invoice_#{status}"
        if email_template = Template::EmailTemplate.where(name: template_name).first
          email = Email.create!(
            booking_portal_client_id: booking_detail.project_unit.booking_portal_client_id,
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
      if recipients.pluck(:phone).present? && booking_detail.project_unit.booking_portal_client.sms_enabled?
        if sms_template = Template::SmsTemplate.where(name: template_name).first
          recipients.each do |recipient|
            Sms.create!(
              booking_portal_client_id: booking_detail.project_unit.booking_portal_client_id,
              recipient_id: recipient.id,
              sms_template_id: sms_template.id,
              triggered_by_id: self.id,
              triggered_by_type: self.class.to_s
            )
          end
        end
      end
    end

    def after_pending_approval_event
      self.raised_date = Time.now
    end

    def after_approved_event
      self.processing_date = Time.now
      self.approved_date = Time.now
      reject_pending_deductions
    end

    def after_rejected_event
      self.processing_date = Time.now
      self.net_amount = 0
      reject_pending_deductions
    end

    def after_re_raise_event
      self.incentive_deduction.pending_approval! if self.incentive_deduction? && self.incentive_deduction.rejected?
    end

    def reject_pending_deductions
      self.incentive_deduction.rejected! if self.incentive_deduction? && self.incentive_deduction.pending_approval?
    end

    def can_approve?
      # TODO: check if cheque details are present
      true
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
