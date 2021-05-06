module ProjectUnitRemindersAndAutoRelease
  class Job
    def self.daily_reminder_for_booking_payment
      ProjectUnit.in(status: ["blocked", 'booked_tentative']).where(auto_release_on: {"$gte" => Date.today}).each do |project_unit|
        days = 0
        if project_unit.auto_release_on.present? && project_unit.auto_release_on > Date.today
          days = (project_unit.auto_release_on - Date.today).to_i
        end
        if days > 0
          if project_unit.booking_portal_client.email_enabled?
            email = Email.create!({
              project_id: project_unit.project_id,
              booking_portal_client_id: project_unit.booking_portal_client_id,
              email_template_id: Template::EmailTemplate.find_by(name: "daily_reminder_for_booking_payment", project_id: project_unit.project_id).id,
              recipients: [project_unit.user],
              cc_recipients: (project_unit.user.manager_id.present? ? [project_unit.user.manager] : []),
              cc: project_unit.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
              triggered_by_id: project_unit.booking_detail.id,
              triggered_by_type: "BookingDetail"
            })
            email.sent!
          end
          if project_unit.booking_portal_client.sms_enabled?
            template = Template::SmsTemplate.where(name: "daily_reminder_for_booking_payment", project_id: project_unit.project_id).first
            Sms.create!(
              project_id: project_unit.project_id,
              booking_portal_client_id: project_unit.booking_portal_client_id,
              recipient_id: project_unit.user_id,
              sms_template_id: template.id,
              triggered_by_id: project_unit.booking_detail.id,
              triggered_by_type: "BookingDetail"
            )
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
