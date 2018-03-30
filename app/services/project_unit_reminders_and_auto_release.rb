module ProjectUnitRemindersAndAutoRelease
  def daily_reminder_for_booking_payment
    ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: {"$gte" => Date.today}).distinct(:user_id).each do |user_id|
      mailer = UserReminderMailer.daily_reminder_for_booking_payment(user_id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      if Rails.env.development?
        SMSWorker.new.perform("", "")
      else
        SMSWorker.perform_async("", "")
      end
    end
  end

  def release_project_unit
    ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: Date.yesterday).each do |unit|
      user_id = unit.user_id
      unit.status = 'available'
      unit.save!
    end
  end
end
