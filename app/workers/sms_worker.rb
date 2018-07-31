require 'net/http'
class SMSWorker
  include Sidekiq::Worker
  extend ApplicationHelper

  def perform(to, content)
    unless Rails.env.development?
      params = {}
      params[:senderid] = SMSWorker.mask
      params[:dest_mobileno] = to
      params[:message] = content
      params[:username] = SMSWorker.username
      params[:pass] = SMSWorker.password
      params[:response] = "Y"

      uri = URI("http://www.smsjust.com/blank/sms/user/urlsms.php")
      uri.query = URI.encode_www_form(params)
      response = Net::HTTP.get_response(uri).body

      if response.starts_with?("ES")
        return {status:"fail", remote_id: response}
      else
        return {status:"success", remote_id: response}
      end
    else
      return {status:"success", remote_id: ""}
    end
  end

  def self.username
    current_client.sms_provider_username
  end

  def self.password
    current_client.sms_provider_password
  end

  def self.mask
    current_client.sms_mask
  end
end
