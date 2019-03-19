class UserRequestObserver < Mongoid::Observer
  def before_save(user_request)
    if user_request.status_changed? && user_request.status == 'resolved'
      user_request.resolved_at = Time.now
    end
  end

  def after_save(user_request)
    user_request.send(user_request.event) if user_request.event.present?
  end

  def after_create(user_request)
    if user_request.status == 'pending'
      user = user_request.user
      project_unit = user_request.project_unit

      if user.booking_portal_client.email_enabled?
        Email.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "#{user_request.class.model_name.element}_request_created").id,
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: user_request.id,
          triggered_by_type: user_request.class.to_s
        )
      end

      if project_unit.present? && user.booking_portal_client.sms_enabled?
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
    end
  end
end
