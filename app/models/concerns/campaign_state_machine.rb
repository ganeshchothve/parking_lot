module CampaignStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :funding, :funded, :live, :paused, :cancelled, :completed

      event :fund, after: %i[send_notification] do
        transitions from: :draft, to: :funding, if: :can_fund?
      end

      event :funding_complete, after: %i[send_notification] do
        transitions from: :funding, to: :funded
      end

      event :go_live, after: %i[send_notification] do
        transitions from: :funded, to: :live, if: :can_go_live?
      end

      event :pause, after: %i[send_notification] do
        transitions from: :live, to: :pause
      end

      event :cancel, after: %i[send_notification] do
        transitions from: :live, to: :cancelled
        transitions from: :paused, to: :cancelled
      end

      event :complete, after: %i[send_notification] do
        transitions from: :live, to: :completed
        transitions from: :paused, to: :completed
      end
    end

    def can_fund?
      true
    end

    def can_go_live?
      true
    end

    def send_notification
      template_name = "campaign_#{self.status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
    end
    
  end
end
