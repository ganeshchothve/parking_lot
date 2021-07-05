module InterestedProjectStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :subscribed, initial: true
      state :approved, :rejected, :blocked

      event :subscribe, after: %i[auto_approve] do
        transitions from: :subscribed, to: :subscribed, if: :can_subscribe?
        transitions from: :rejected, to: :subscribed, if: :can_subscribe?
      end

      event :approve, after: %i[send_notification] do
        transitions from: :subscribed, to: :approved
        transitions from: :blocked, to: :approved
      end

      event :reject, after: %i[send_notification] do
        transitions from: :subscribed, to: :rejected
      end

      event :block, after: %i[send_notification] do
        transitions from: :approved, to: :blocked
      end
    end

    def can_subscribe?
      true
    end

    def auto_approve
      # TODO: Can have approval process here
      self.approve!
    end

    def send_notification
      template_name = "interested_project_#{self.status}_notification"
      # TODO: Send Email, sms, in-app messages etc
    end
  end
end
