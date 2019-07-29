require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(user_id, st=nil)
    return false if Rails.env.test?
    user = User.where(id: user_id).first
    return false unless user
    priority = PortalStagePriority.all.collect{|x| [x.stage, x.priority]}.to_h
    if st.present? && priority[st].present?
      if user.portal_stages.empty?
        user.portal_stages << PortalStage.new(stage: st, priority: priority[st])
        sell_do(user, st)
      elsif user.portal_stage.priority.to_i <= priority[st].to_i
        user.portal_stages.where(stage:  st).present? ? user.portal_stages.where(stage:  st).first.set(updated_at: Time.now, priority: priority[st]) : user.portal_stages << PortalStage.new(stage: st, priority: priority[st])
        sell_do(user, st)
      end
    else
      user.portal_stage
    end
  end

  def sell_do (user, stage)
    score = 10
    MixpanelPusherWorker.perform_async(user.mixpanel_id, stage, {}) if current_client.mixpanel_token.present?
    if current_client.selldo_api_key.present?
      if user.buyer? && stage.present? && user.lead_id.present?
        params = {
          lead_id: user.lead_id,
          mixpanel_id: (user.mixpanel_id.present? && user.mixpanel_id != "undefined" && user.mixpanel_id != "null") ? user.mixpanel_id : nil,
          score: score,
          custom_data: {
            portal_stage: stage
          },
          api_key: current_client.selldo_api_key
        }
        RestClient.post("https://app.sell.do/api/leads/create", params)
      end
    end
  end
end
