class UserMailer < ApplicationMailer
  def send_change_in_manager user_id
    @user = User.where(id: user_id).first
    @client = @user.booking_portal_client
    if @user.buyer? && @user.manager_id.present?
      make_bootstrap_mail(from: @client.sender_email, to: User.where(booking_portal_client_id: @client.id).in(role: ["admin", "cp_admin"]).distinct(:email), subject: "Channel Partner for Customer: #{@user.name} Updated")
    end
  end
end
