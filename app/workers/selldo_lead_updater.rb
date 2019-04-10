require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(user_id, st=nil)
    return false if Rails.env.test?
    user = User.find user_id
    project_units = user.project_units.all
    stage = nil
    stage = 'blocked' if project_units.select{|x| x.status == 'blocked'}.present?
    stage = 'booked_tentative' if project_units.select{|x| x.status == 'booked_tentative'}.present?
    stage = 'booked_confirmed' if project_units.select{|x| x.status == 'booked_confirmed'}.present?
    if st.present? && stage.blank?
      stage = st
    elsif stage.blank?
      stage = 'user_kyc_done' if user.user_kycs.present?
      stage = 'hold' if project_units.select{|x| x.status == 'hold'}.present?
    end
    score = 10
    MixpanelPusherWorker.perform_async(user.mixpanel_id, stage, {}) if current_client.mixpanel_token.present?
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
