class PaymentReminderWorker
  include Sidekiq::Worker

  def perform(options={})
    options = options.with_indifferent_access
    user = User.find options[:user_id]
    if user.receipts.blank?
      email_template = Template::EmailTemplate.where(project_id: options[:project_id], name: "no_payment_hour_1").first
      if email_template.present?
        email = Email.create!(
          project_id: options[:project_id],
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: email_template.id,
          cc: [user.booking_portal_client.notification_email],
          recipients: [user],
          cc_recipients: [],
          triggered_by_id: user.id,
          triggered_by_type: user.class.to_s
        )
        email.sent!
      end
      sms_template = Template::SmsTemplate.where(project_id: options[:project_id], name: "no_payment_hour_1").first
      Sms.create!(
        project_id: options[:project_id],
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: options[:user_id],
        sms_template_id: sms_template.id,
        triggered_by_id: user.id,
        triggered_by_type: user.class.to_s
      ) if sms_template.present?
    end
  end
end
