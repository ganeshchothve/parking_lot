module LeadNotifications

  def get_recipients
    recipients = []
    recipients << self.manager if self.manager.present?
    recipients << self.manager.manager if self.manager.try(:manager).present?
    recipients
  end

  def send_create_notification
    template_name = "lead_create"
    send_notification(template_name)
  end

  def send_update_notification
    template_name = "lead_update"
    send_notification(template_name)
  end

  def send_notification template_name
    template = Template::EmailTemplate.where(name: template_name, project_id: self.project_id).first
    recipients = get_recipients
    if recipients.present? && template.present?
       email = Email.create!(
        booking_portal_client_id: self.user.booking_portal_client_id,
        email_template_id: template.id,
        recipients: recipients.flatten,
        cc_recipients: [],
        triggered_by_id: self.id,
        triggered_by_type: self.class.to_s,
       )
       email.sent!
    end
  end

end