class UserRequestMailer < ApplicationMailer
  def send_pending user_request_id
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: "Cancellation Requested for Unit: #{@project_unit.name}")
  end

  def send_resolved user_request_id
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: "Cancellation Request for Unit: #{@project_unit.name} Resolved")
  end

  def send_swapped user_request_id
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.project_unit
    @alternate_project_unit = @user_request.alternate_project_unit
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: "Swap request resolved for Unit: #{@project_unit.name} with new unit #{@alternate_project_unit.name}")
  end
end
