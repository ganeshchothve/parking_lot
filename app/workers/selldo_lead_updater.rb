require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker

  def perform(user_id, st=nil)
    user = User.find user_id
    project_units = user.project_units.all
    stage = nil

    if st.present?
      stage = st
    else
      stage = 'booked_confirmed' if stage.blank? && project_units.select{|x| x.status == 'booked_confirmed'}.present?
      stage = 'booked_tentative' if stage.blank? && project_units.select{|x| x.status == 'booked_tentative'}.present?
      stage = 'blocked' if stage.blank? && project_units.select{|x| x.status == 'blocked'}.present?
      stage = 'hold' if stage.blank? && project_units.select{|x| x.status == 'hold'}.present?
      stage = 'user_kyc_done' if stage.blank? && user.user_kycs.present?
    end

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
