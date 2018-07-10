require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker
  def perform(user_id, st=nil)
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
    MixpanelPusherWorker.perform_async(user.mixpanel_id, stage, {})
    if stage.present?
      params = {
        'api_key': ENV_CONFIG['selldo']['api_key'],
        'sell_do[form][lead][lead_id]': user.lead_id,
        'sell_do[form][custom][portal_stage]': stage,
        'sell_do[campaign][srd]': ENV_CONFIG['selldo']['default_srd']
      }
      RestClient.post("https://app.sell.do/api/leads/create", params)
    end
  end
end
