class NotifyAdminWorker
  include Sidekiq::Worker

  def perform user_id, channel_partner_id
    NotifyAdminMailer.send_channel_partner_activity(user_id, channel_partner_id).deliver
  end
end
