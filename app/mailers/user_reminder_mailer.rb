class UserReminderMailer < ApplicationMailer

  def daily_reminder_for_booking_payment user_id
    @user = User.find(user_id)
    @project_units = @user.project_units.in(status: ['blocked', 'booked_tentative']).all
    # TODO: handle specific case if its already 6 days - mention we will release the unit tomorrow
    if @project_units.length > 1
      subject = "Payment for some of your units is pending"
    else
      subject = "Payment for your unit #{@project_units.first.name} is pending"
    end
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    mail(to: @user.email, cc: cc, subject: subject)
  end
end
