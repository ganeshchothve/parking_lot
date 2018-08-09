require 'net/http'
class SMSWorker
  include Sidekiq::Worker

  def perform sms_id
    unless Rails.env.development?
      Communication::Sms::Smsjust.execute sms_id
    end
  end
end
