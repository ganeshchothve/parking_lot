module MeetingStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :scheduled, :cancelled, :completed

      event :schedule, after: %i[send_notification] do
        transitions from: :draft, to: :scheduled, if: :can_schedule?
      end

      event :cancel, after: %i[send_notification] do
        transitions from: :scheduled, to: :cancelled
      end

      event :complete, after: %i[send_notification] do
        transitions from: :scheduled, to: :completed
      end
    end

    def can_schedule?
      true
    end

    def send_notification
      template_name = "meeting_#{self.status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end
  end
end
