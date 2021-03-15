module Reminders
  class PostPaymentWorker
    include Sidekiq::Worker

    def perform user_id, day
      user = User.find user_id
      email_template = Template::EmailTemplate.where(name: "no_booking_day_#{day.to_i}")
      if email_template.present?
        email = Email.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: email_template.first.id,
          cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
          recipients: [user],
          cc_recipients: [],
          triggered_by_id: user.id,
          triggered_by_type: user.class.to_s
        )
        email.sent!
      end
      sms_template = Template::SmsTemplate.where(name: "no_booking_day_#{day.to_i}")
      Sms.create!(
            booking_portal_client_id: user.booking_portal_client_id,
            recipient_id: user_id,
            sms_template_id: sms_template.first.id,
            triggered_by_id: user.id,
            triggered_by_type: user.class.to_s
          ) if sms_template.present?

      template = Template::NotificationTemplate.where(name: "no_booking_day_#{day.to_i}").first
      if template.present? && user.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: user.id,
          recipient_id: user.id,
          booking_portal_client_id: user.booking_portal_client.id
        )
        push_notification.save
      end
    end
  end
end
