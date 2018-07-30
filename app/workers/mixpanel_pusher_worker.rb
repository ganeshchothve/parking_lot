class MixpanelPusherWorker
  include ApplicationHelper
  include Sidekiq::Worker

  def perform(mixpanel_id, stage, params = {})
    token = current_client.mixpanel_token
    if(token)
      tracker = Mixpanel::Tracker.new(token)
      tracker.track(mixpanel_id, stage, params)
    end
  end
end
