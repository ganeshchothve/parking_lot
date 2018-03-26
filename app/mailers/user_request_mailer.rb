class UserRequestMailer < ApplicationMailer
  def send_pending user_request_id
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Cancellation Requested for Unit: #{@project_unit.name}")
  end

  def send_resolved user_request_id
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Cancellation Request for Unit: #{@project_unit.name} Resolved")
  end
end
