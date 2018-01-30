module ProjectUnitRemindersAndAutoRelease
  def daily_reminder_for_booking_payment
    ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: {"$gte" => Date.today}).distinct(:user_id).each do |user_id|
      UserReminderMailer.daily_reminder_for_booking_payment(user_id.to_s).deliver_later
      SMSWorker.perform_async(to: "", content: "")
    end
  end

  def release_project_unit
    ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: Date.yesterday).each do |unit|
      user_id = unit.user_id
      unit.status = 'available'
      if unit.save
        ProjectUnitMailer.released(user_id.to_s, unit.id.to_s).deliver_later
        SMSWorker.perform_async(to: "", content: "")
      else
        #TODO: Notify Team amura about an issue
      end
    end
  end
end
