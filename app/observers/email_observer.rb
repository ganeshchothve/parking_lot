class EmailObserver < Mongoid::Observer
  # def before_validation email
  #   email.in_reply_to = "thread-#{email.id}@#{Email.default_email_domain}"
  # end

  def before_create email
    email.to ||= []
    email.cc ||= []
    email.to = email.recipients.distinct(:email)
    email.cc = email.cc_recipients.distinct(:email)
  end

  def before_save email
    triggered_by = email.triggered_by
    if email.email_template_id.present?
      email_template = Template::EmailTemplate.find email.email_template_id
      current_client = email.booking_portal_client
      current_project = current_client.projects.first
      email.body = ERB.new(email.booking_portal_client.email_header).result( binding ) + email_template.parsed_content(triggered_by) + ERB.new(email.booking_portal_client.email_footer).result( binding )
      email.text_only_body = TemplateParser.parse(email_template.text_only_body, triggered_by)
      email.subject = email_template.parsed_subject(triggered_by)
      # email.attachment_ids ||= []
      # email.attachment_ids += email_template.docs.distinct(:id)
      # email.attachment_ids += email_template.attachment_ids
    else
      email.body = TemplateParser.parse(email.body, triggered_by)
      email.text_only_body = TemplateParser.parse(email.text_only_body, triggered_by)
      email.subject = TemplateParser.parse(email.subject, triggered_by)
    end
  end

  def after_create email
    if Rails.env.production? || Rails.env.staging?
      Communication::Email::Mailgun.execute(email.id.to_s)
    else
      ApplicationMailer.test({
        to: email.recipients.distinct(:email),
        cc: email.cc,
        body: email.body,
        subject: email.subject
      }).deliver
    end
    # if email.attachment_ids.present?
    #   email.attachments.each do |attachment|
    #     if attachment.associations.where(subject_class: "Email",subject_id: email.id).count == 0
    #       attachment.associations.create(subject_class: "Email",subject_id: email.id)
    #     end
    #   end
    # end
  end

  def after_update email
    # if email.attachment_ids.present?
    #   email.attachments.each do |attachment|
    #     if attachment.associations.where(subject_class: "Email",subject_id: email.id).count == 0
    #       attachment.associations.create(subject_class: "Email",subject_id: email.id)
    #     end
    #   end
    # end
  end
end
