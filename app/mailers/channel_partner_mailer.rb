class ChannelPartnerMailer < ApplicationMailer
  def send_create channel_partner_id, client_id
    @channel_partner = ChannelPartner.where(booking_portal_client_id: client_id, id: channel_partner_id).first
    if @channel_partner
      emails = @channel_partner.manager_email || User.where(booking_portal_client_id: @channel_partner.booking_portal_client_id, role: "cp_admin").distinct(:email)
      emails = @channel_partner.booking_portal_client.notification_email.to_s.split(',').map(&:strip) if emails.blank?
      make_bootstrap_mail(from: @channel_partner.booking_portal_client.sender_email, to: emails, subject: "New channel partner registered on your website") if emails.present?
    end
  end

  def send_user_activated_with_other channel_partner_id, user_id, client_id
    @channel_partner = ChannelPartner.where(booking_portal_client_id: client_id, id: channel_partner_id).first
    if @channel_partner
      @user = User.where(booking_portal_client_id: @channel_partner.booking_portal_client_id, id: user_id).first
      make_bootstrap_mail(from: @channel_partner.booking_portal_client.sender_email, to: @channel_partner.booking_portal_client.notification_email.to_s.split(',').map(&:strip), subject: "New channel partner registered on your website") if @channel_partner.booking_portal_client.notification_email.present?
    end
  end
end
