class UserMailer < ApplicationMailer
  def send_change_in_manager user_id
    @user = User.find user_id
    if @user.buyer? && @user.manager_id.present?
      make_bootstrap_mail(to: User.in(role: ["admin", "cp_admin"]).distinct(:email), subject: "Channel Partner for Customer: #{@user.name} Updated")
    end
  end
end
