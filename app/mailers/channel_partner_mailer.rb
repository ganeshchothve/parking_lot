class ChannelPartnerMailer < ApplicationMailer
  def send_create channel_partner_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    emails = @channel_partner.manager_email || User.where(role: "cp_admin").distinct(:email)
    emails = @channel_partner.booking_portal_client.notification_email.to_s.split(',').map(&:strip) if emails.blank?
    make_bootstrap_mail(to: emails, subject: "New channel partner registered on your website") if emails.present?
  end

  def send_user_activated_with_other channel_partner_id, user_id
    @channel_partner = ChannelPartner.find(channel_partner_id)
    @user = User.find(user_id)
    make_bootstrap_mail(to: @channel_partner.booking_portal_client.notification_email.to_s.split(',').map(&:strip), subject: "New channel partner registered on your website") if @channel_partner.booking_portal_client.notification_email.present?
  end
end
