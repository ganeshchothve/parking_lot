class UserRequestService
  attr_accessor :user_request, :user

  def initialize(user_request)
    @user_request = user_request
    @user = @user_request.user
    send_notifications
  end

  def send_email
    email = Email.create!(
      project_id: self.project_id,
      booking_portal_client_id: user.booking_portal_client_id,
      email_template_id: Template::EmailTemplate.where(name: "#{user_request.class.model_name.element}_request_pending", project_id: self.project_id, booking_portal_client_id: user.booking_portal_client_id).first.try(:id),
      recipients: [user],
      cc_recipients: (user.manager.present? ? [user.manager] : []),
      cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
      triggered_by_id: user_request.id,
      triggered_by_type: user_request.class.to_s
    )
    email.sent!
  end

  def send_sms
    template = Template::SmsTemplate.where(booking_portal_client_id: user.booking_portal_client_id, name: "#{user_request.class.model_name.element}_request_created", project_id: self.project_id).first
    if template.present?
      Sms.create!(
        project_id: self.project_id,
        booking_portal_client_id: user.booking_portal_client_id,
        recipient_id: user.id,
        sms_template_id: template.id,
        triggered_by_id: user_request.id,
        triggered_by_type: user_request.class.to_s
      )
    end
  end

  def send_notifications
    send_email if user.booking_portal_client.email_enabled?
    send_sms if user_request.requestable && user.booking_portal_client.sms_enabled?
  end
end
