module ReceiptStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status do
      state :pending, initial: true
      state :success, :clearance_pending, :failed, :available_for_refund, :refunded

      event :pending do
        transitions from: :pending, to: :pending
      end

      event :pending_clearance do
        transitions from: :pending, to: :clearance_pending, if: :can_move_to_clearance?, after: :send_sms_notification
      end

      event :clearance_pending do
        transitions from: :clearance_pending, to: :clearance_pending
      end

      event :success do
        transitions from: :success, to: :success
        transitions from: :clearance_pending, to: :success, after: [:send_sms_notification, :send_success_notification], unless: :new_record?
      end

      event :available_for_refund do
        transitions from: :available_for_refund, to: :available_for_refund
        transitions from: :success, to: :available_for_refund, if: :available_for_refund?
      end

      event :refunded do
        transitions from: :refunded, to: :refunded
      end

      event :refund do
        transitions from: :available_for_refund, to: :refunded
      end

      event :failed do
        transitions from: :pending, to: :failed, after: :send_sms_notification
        transitions from: :failed, to: :failed
      end

    end

    def available_for_refund?
      self.booking_detail.blank? || self.booking_detail.status == "cancelled"
    end

    def can_move_to_clearance?
      self.persisted? || (self.project_unit_id.present? && self.project_unit.status == "hold")
    end

    def send_success_notification
      if self.user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "receipt_success").id,
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        })
      end
    end

    def send_failure_notification
      if self.user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "receipt_failed").id,
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        })
      end
    end

    def send_clearance_pending_notification
      if self.user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "receipt_clearance_pending").id,
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        })
      end
    end

    def send_sms_notification
      if self.user.booking_portal_client.sms_enabled?
        Sms.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          recipient_id: self.user_id,
          sms_template_id: SmsTemplate.find_by(name: "receipt_#{self.status}").id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s
        )
      end
    end

    def send_pending_notification
      # Send email to crm team if cheque non-online & pending
      if self.status == 'pending' && self.payment_mode != 'online'
        if user.booking_portal_client.email_enabled?
          Email.create!({
            booking_portal_client_id: user.booking_portal_client_id,
            email_template_id:Template::EmailTemplate.find_by(name: "receipt_pending_offline").id,
            recipients: [user],
            cc_recipients: (user.manager_id.present? ? [user.manager] : []),
            triggered_by_id: receipt.id,
            triggered_by_type: receipt.class.to_s
          })
        end
        if self.user.booking_portal_client.sms_enabled?
          Sms.create!(
            booking_portal_client_id: user.booking_portal_client_id,
            recipient_id: self.user_id,
            sms_template_id: SmsTemplate.find_by(name: "receipt_pending").id,
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
        end
      end
    end
  end
end
