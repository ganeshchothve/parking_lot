module Reminders
  class PostRegistrationWorker
    include Sidekiq::Worker

    def perform user_id, day
      user = User.find user_id
      email_template = Template::EmailTemplate.where(name: "not_confirmed_day_#{day.to_i}")
      if email_template.present?
        email = Email.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: email_template.first.id,
          cc: [user.booking_portal_client.notification_email],
          recipients: [user],
          cc_recipients: [],
          triggered_by_id: user.id,
          triggered_by_type: user.class.to_s
        )
        email.sent!
      end
      sms_template = Template::SmsTemplate.where(name: "not_confirmed_day_#{day.to_i}")
      Sms.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: user_id,
        sms_template_id: sms_template.first.id,
        triggered_by_id: user.id,
        triggered_by_type: user.class.to_s
      ) if sms_template.present?
    end
  end
end
