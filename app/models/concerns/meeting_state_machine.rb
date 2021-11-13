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
        transitions from: :completed, to: :cancelled
      end

      event :complete, after: %i[send_notification] do
        transitions from: :scheduled, to: :completed
        transitions from: :draft, to: :completed, if: :can_complete?
        transitions from: :cancelled, to: :completed, if: :can_complete?
      end
    end

    def can_schedule?
      scheduled_on >= Time.now.beginning_of_day
    end

    def can_complete?
      scheduled_on < Time.now.beginning_of_day
    end

    def send_notification
      template_name = "meeting_#{self.status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end
  end
end
