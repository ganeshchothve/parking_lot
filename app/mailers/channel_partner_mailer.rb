class ChannelPartnerMailer < ApplicationMailer
  def send_create channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    mail(to: channel_partner_management_team + default_team, subject: "New channel partner registered on website")
  end

  def send_active channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
  end

  def send_user_activated_with_other channel_partner_id, user_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    @user = User.find(user_id)
  end
end
