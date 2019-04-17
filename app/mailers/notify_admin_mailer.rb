class NotifyAdminMailer < ApplicationMailer
  def send_channel_partner_activity user_id , channel_partner_id
    @user = User.find(user_id)
    @channel_partner = User.find(channel_partner_id) 
    make_bootstrap_mail(to: User.in(role: ["admin", "superadmin"]).distinct(:email), subject: "Channel Partner tried to add an existing lead .")
  end
end
