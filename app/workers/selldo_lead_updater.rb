require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(user_id, st=nil, options={})
    return false if Rails.env.test?
    user = User.where(id: user_id).first
    return false unless user
    priority = PortalStagePriority.all.collect{|x| [x.stage, x.priority]}.to_h
    if st.present? && priority[st].present?
      if user.portal_stages.empty?
        user.portal_stages << PortalStage.new(stage: st, priority: priority[st])
      elsif user.portal_stage.priority.to_i <= priority[st].to_i
        user.portal_stages.where(stage:  st).present? ? user.portal_stages.where(stage:  st).first.set(updated_at: Time.now, priority: priority[st]) : user.portal_stages << PortalStage.new(stage: st, priority: priority[st])
      end
      if st == 'payment_done' && options["token_number"].present?
        token_numbers = user.receipts.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).distinct(:token_number)
      end
      sell_do(user, st, token_numbers)
    else
      user.portal_stage
    end
  end

  def sell_do (user, stage, token_numbers)
    score = 10
    custom_hash = { portal_stage: stage }
    custom_hash[:token_number] = token_numbers if token_numbers.present?
    MixpanelPusherWorker.perform_async(user.mixpanel_id, stage, {}) if current_client.mixpanel_token.present?
    if current_client.selldo_api_key.present?
      if user.buyer? && stage.present? && user.lead_id.present?
        params = {
          lead_id: user.lead_id,
          mixpanel_id: (user.mixpanel_id.present? && user.mixpanel_id != "undefined" && user.mixpanel_id != "null") ? user.mixpanel_id : nil,
          score: score,
          custom_data: custom_hash,
          api_key: current_client.selldo_api_key
        }
        RestClient.post("https://app.sell.do/api/leads/create", params)
      end
    end
  end
end
