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
        days = project_unit.promote_future_payment_days
        if days.present?
          template = SmsTemplate.where(name: "promote_future_payment_#{days}").first
          Sms.create!(
            booking_portal_client_id: project_unit.booking_portal_client_id,
            recipient_id: project_unit.user_id,
            sms_template_id: template.id,
            triggered_by_id: project_unit.id,
            triggered_by_type: project_unit.class.to_s
          )
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
