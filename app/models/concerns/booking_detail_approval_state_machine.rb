module BookingDetailApprovalStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    attr_accessor :approval_event
    field :approval_status, type: String

    aasm :approval_status, column: :approval_status, whiny_transitions: false, namespace: :verification do
      state :pending, initial: true
      state :approved, :rejected

      event :approve, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :approved
      end

      event :reject, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :rejected
      end

      event :pending do
        transitions from: :rejected, to: :pending
      end
    end

    def send_approval_status_notification
      template_name = "booking_detail_approval_status_#{self.approval_status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end

    def move_to_next_approval_state!(status)
      if self.respond_to?("may_#{status}?") && self.send("may_#{status}?")
        self.aasm(:approval_status).fire!(status.to_sym)
      else
        self.errors.add(:base, 'Invalid transition')
      end
      self.errors.empty?
    end

  end
end
