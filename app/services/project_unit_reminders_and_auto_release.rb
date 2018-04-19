module ProjectUnitRemindersAndAutoRelease
  class Job
    def self.daily_reminder_for_booking_payment
      ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: {"$gte" => Date.today}).each do |project_unit|
        # mailer = UserReminderMailer.daily_reminder_for_booking_payment(project_unit.id.to_s)
        # if Rails.env.development?
        #   mailer.deliver
        # else
        #   mailer.deliver_later
        # end
        message = project_unit.promote_future_payment_message
        if Rails.env.development?
          SMSWorker.new.perform(project_unit.user.phone.to_s, message)
        else
          SMSWorker.perform_async(project_unit.user.phone.to_s, message)
        end
      end
    end

    def self.release_project_unit
      ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: Date.yesterday).each do |unit|
        user_id = unit.user_id
        unit.make_available
        unit.save!
      end
    end
  end
end
