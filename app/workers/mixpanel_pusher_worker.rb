class MixpanelPusherWorker
  include ApplicationHelper
  include Sidekiq::Worker

  def perform(client_id, mixpanel_id, stage, params = {})
    return if client_id.blank?
    client = Client.where(id: client_id).first
    if client && client.mixpanel_token.present?
      token = client.mixpanel_token
      if(token)
        tracker = Mixpanel::Tracker.new(token)
        tracker.track(mixpanel_id, stage, params)
      end
    end
  end
end
