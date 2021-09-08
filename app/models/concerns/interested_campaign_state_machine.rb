module InterestedCampaignStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :subscribed, initial: true
      state :participating

      event :pay, after: %i[send_notification] do
        transitions from: :subscribed, to: :participating
      end
    end

    def send_notification
      template_name = "interested_campaign_#{self.status}_notification"
      # TODO: Send Email, sms, in-app messages etc
    end
  end
end