class TokenDetailsUpdateNotification
  include Sidekiq::Worker
  sidekiq_options queue: 'discount'

  def perform user_id, receipt_id
    user = User.find user_id
    if user
      email_template = ::Template::EmailTemplate.where(name: "updated_token_details")
      if email_template.present?
        email = Email.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: email_template.first.id,
          bcc: [user.booking_portal_client.notification_email],
          recipients: [user],
          cc_recipients: [],
          triggered_by_id: receipt_id,
          triggered_by_type: "Receipt"
        )
        email.sent!
      end
      sms_template = Template::SmsTemplate.where(name: "updated_token_details")
      if sms_template.present?
        Sms.create!(
            booking_portal_client_id: user.booking_portal_client_id,
            recipient_id: user.id,
            sms_template_id: sms_template.first.id,
            triggered_by_id: receipt_id,
            triggered_by_type: "Receipt"
          )
      end
    end
  end
end
