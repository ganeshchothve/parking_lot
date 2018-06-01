module ProjectUnitRemindersAndAutoRelease
  class Job
    def self.daily_reminder_for_booking_payment
      ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: {"$gte" => Date.today}).each do |project_unit|
        days = (project_unit.auto_release_on - Date.today).to_i
        if [9,7,5,3,2,1].include?(days)
          mailer = UserReminderMailer.daily_reminder_for_booking_payment(project_unit.id.to_s)
          if Rails.env.development?
            mailer.deliver
          else
            mailer.deliver_later
          end
        end
        message = project_unit.promote_future_payment_message
        if message.present?
          if Rails.env.development?
            SMSWorker.new.perform(project_unit.user.phone.to_s, message)
          else
            SMSWorker.perform_async(project_unit.user.phone.to_s, message)
          end
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
