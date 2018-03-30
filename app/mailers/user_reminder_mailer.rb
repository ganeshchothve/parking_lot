class UserReminderMailer < ApplicationMailer

  def daily_reminder_for_booking_payment project_unit_id, user_id
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    # TODO: handle specific case if its already 6 days - mention we will release the unit tomorrow
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: subject)
  end
end
