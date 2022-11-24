module Reminders
  class PostKycWorker
    include Sidekiq::Worker

    def perform user_id, day, project_id
      user = User.where(id: user_id).first
      booking_portal_client_id = user.try(:booking_portal_client_id)
      email_template = Template::EmailTemplate.where(booking_portal_client_id: booking_portal_client_id, project_id: project_id, name: "no_payment_day_#{day.to_i}").first
      if email_template.present?
        email = Email.create!(
              project_id: project_id,
              booking_portal_client_id: user.booking_portal_client_id,
              email_template_id: email_template.id,
              cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
              recipients: [user],
              cc_recipients: [],
              triggered_by_id: user.id,
              triggered_by_type: user.class.to_s
            )
        email.sent!
      end
      sms_template = Template::SmsTemplate.where(booking_portal_client_id: booking_portal_client_id, project_id: project_id, name: "no_payment_day_#{day.to_i}").first
      Sms.create!(
        project_id: project_id,
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: user_id,
        sms_template_id: sms_template.id,
        triggered_by_id: user.id,
        triggered_by_type: user.class.to_s
      ) if sms_template.present?
    end
  end
end
