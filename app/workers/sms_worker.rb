require 'net/http'
class SMSWorker
  include Sidekiq::Worker

  def perform(to, content, type="trans")
    if to.present? && content.present? && Rails.env.production? && SMSWorker.auth_key.present?
      params = {}
      headers = {}
      sms = sms
      params[:is_file] = 'no'
      params[:sms_to] = to
      params[:sms_text] = content
      headers[:auth_key] = SMSWorker.auth_key
      params[:sms_from] = SMSWorker.mask
      params[:sms_type] = (type == 'promotional' ? 'promo' : 'trans')

      url = "http://etsrds.kapps.in/webapi/amura/api/amura_sms_api.py"
      params = params.with_indifferent_access
      headers = headers.with_indifferent_access
      resp = JSON.parse ::RestClient::Request.execute(method: :post, url: url, payload: params, headers: headers)
    end
  end

  def self.auth_key
    ""
  end

  def self.mask
    "SellDo"
  end
end
