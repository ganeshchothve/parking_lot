class MixpanelPusherWorker
  include Sidekiq::Worker

  def perform(mixpanel_id, stage, params = {})
    token = ENV_CONFIG['mixpanel_token']
    if(token)
      tracker = Mixpanel::Tracker.new(token)
      tracker.track(mixpanel_id, stage, params)
    end
  end
end
