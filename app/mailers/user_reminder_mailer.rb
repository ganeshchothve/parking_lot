class UserReminderMailer < ApplicationMailer

  def daily_reminder_for_booking_payment project_unit_id
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    @days = (@project_unit.auto_release_on - Date.today).to_i
    @client = @user.booking_portal_client
    mail(to: @user.email, cc: cc, subject: "Comfirm Your Booking - " + @project_unit.project_name + " at " + @client.name)
  end
end
