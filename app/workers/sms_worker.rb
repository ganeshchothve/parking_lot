require 'net/http'
class SMSWorker
  include Sidekiq::Worker

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
    end
  end

  def self.username
    ENV_CONFIG[:sms][:username]
  end

  def self.password
    ENV_CONFIG[:sms][:password]
  end

  def self.mask
    "SellDo"
  end
end
