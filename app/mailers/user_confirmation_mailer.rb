class UserConfirmationMailer < ApplicationMailer
  def send_confirmation (user_id, token)
    @resource = User.find(user_id)
    @token = token
    mail(to: @resource.email, subject: "Confirmation instructions")
  end
end
