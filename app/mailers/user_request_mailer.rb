class UserRequestMailer < ApplicationMailer
  def send_pending(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @name = @user_request.requestable.name
    @cp = @user.manager
    cc = @cp.present? ? [@cp.email] : []
    make_bootstrap_mail(from: @user_request.booking_portal_client.sender_email, to: @user.email, cc: cc, subject: "Cancellation Requested for #{@name}")
  end

  def send_resolved(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @name = @user_request.requestable.name
    @cp = @user.manager
    cc = @cp.present? ? [@cp.email] : []
    make_bootstrap_mail(from: @user_request.booking_portal_client.sender_email, to: @user.email, cc: cc, subject: "Cancellation Request for #{@name} Resolved")
  end

  def send_swapped(user_request_id)
    @user_request = UserRequest.find(user_request_id)
    @user = @user_request.user
    @project_unit = @user_request.requestable.name
    @alternate_project_unit = @user_request.alternate_project_unit
    @cp = @user.manager
    cc = @cp.present? ? [@cp.email] : []
    make_bootstrap_mail(from: @user_request.booking_portal_client.sender_email, to: @user.email, cc: cc, subject: "Swap request resolved for Unit: #{@project_unit.name} with new unit #{@alternate_project_unit.name}") if @project_unit.present?
  end
end
