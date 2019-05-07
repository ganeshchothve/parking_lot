class UserRequestService
  attr_accessor :user_request, :user

  def initialize(user_request)
    @user_request = user_request
    @user = @user_request.user
    send_notifications
  end

  def send_email
    Email.create!(
      booking_portal_client_id: user.booking_portal_client_id,
      email_template_id: Template::EmailTemplate.find_by(name: "#{user_request.class.model_name.element}_request_created").id,
      recipients: [user],
      cc_recipients: (user.manager_id.present? ? [user.manager] : []),
      triggered_by_id: user_request.id,
      triggered_by_type: user_request.class.to_s
    )
  end

  def send_sms
    template = Template::SmsTemplate.where(name: "#{user_request.class.model_name.element}_request_created").first
    if template.present?
      Sms.create!(
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
    send_sms if user_request.booking_detail.project_unit.present? && user.booking_portal_client.sms_enabled?
  end
end