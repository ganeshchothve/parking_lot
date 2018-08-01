class ChannelPartnerMailer < ApplicationMailer
  def send_create channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    make_bootstrap_mail(to: current_client.notification_email, subject: "New channel partner registered on your website")
  end

  def send_user_activated_with_other channel_partner_id, user_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    @user = User.find(user_id)
    make_bootstrap_mail(to: current_client.notification_email, subject: "New channel partner registered on your website")
  end
end
