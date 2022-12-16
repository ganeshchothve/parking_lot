class NotifyAdminMailer < ApplicationMailer
  def send_channel_partner_activity user_id , channel_partner_id
    @user = User.where(id: user_id).first
    @channel_partner = User.where(id: channel_partner_id).first
    @client = @user.booking_portal_client
    make_bootstrap_mail(from: @client.sender_email, to: User.where(booking_portal_client_id: @client.id).in(role: ["admin", "superadmin"]).distinct(:email), subject: "Channel Partner tried to add an existing lead .")
  end
end
