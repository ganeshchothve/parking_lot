require 'net/http'
class SelldoLeadUpdater
  include Sidekiq::Worker

  def perform(user_id, st=nil)
    user = User.find user_id
    project_units = user.project_units.all
    stage = nil

    stage = 'booked_confirmed' if stage.blank? && project_units.find{|x| x.status == 'booked_confirmed'}.present?
    stage = 'booked_tentative' if stage.blank? && project_units.find{|x| x.status == 'booked_tentative'}.present?
    stage = 'blocked' if stage.blank? && project_units.find{|x| x.status == 'blocked'}.present?
    stage = 'hold' if stage.blank? && project_units.find{|x| x.status == 'hold'}.present?
    stage = 'hold_payment_dropoff' if stage.blank? && st == "hold_payment_dropoff"
    stage = 'user_kyc_done' if stage.blank? && user.user_kycs.present?

    if stage.present?
      params = {
        'api_key': ENV_CONFIG['selldo']['api_key'],
        'sell_do[form][lead][lead_id]': user.lead_id,
        'sell_do[form][custom][portal_stage]': stage
      }
      RestClient.post("https://app.sell.do/api/leads/create", params)
    end
  end
end
