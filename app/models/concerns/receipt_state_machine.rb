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
        transitions from: :pending, to: :clearance_pending, if: :can_move_tp_clearance?, after: :send_sms_notification
      end

      event :clearance_pending do
        transitions from: :clearance_pending, to: :clearance_pending
      end

      event :success do
        transitions from: :success, to: :success
        transitions from: :clearance_pending, to: :success, after: [:send_sms_notification, :send_success_notification]
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

    def can_move_tp_clearance
      self.persisted? || (self.project_unit_id.present? && self.project_unit.status == "hold")
    end

    def send_success_notification
      mailer = ReceiptMailer.send_success(self.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end

    def send_failure_notification
      mailer = ReceiptMailer.send_failure(self.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end

    def send_clearance_pending_notification
      mailer = ReceiptMailer.send_clearance_pending(self.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end

    def send_sms_notification
      Sms.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: self.user_id,
        sms_template_id: SmsTemplate.find_by(name: "receipt_#{self.status}").id,
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s
      )
    end

    def send_pending_notification
      # Send email to crm team if cheque non-online & pending
      if self.status == 'pending' && self.payment_mode != 'online'
        mailer = ReceiptMailer.send_pending_non_online(self.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
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
