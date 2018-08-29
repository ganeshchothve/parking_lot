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
      begin
        email.body = ERB.new(email.booking_portal_client.email_header).result( binding ) + email_template.parsed_content(triggered_by) + ERB.new(email.booking_portal_client.email_footer).result( binding )
      rescue => e
        email.body = ""
      end
      email.text_only_body = TemplateParser.parse(email_template.text_only_body, triggered_by)
      email.subject = email_template.parsed_subject(triggered_by)
    else
      email.body = TemplateParser.parse(email.body, triggered_by)
      email.text_only_body = TemplateParser.parse(email.text_only_body, triggered_by)
      email.subject = TemplateParser.parse(email.subject, triggered_by)
    end
  end

  def after_create email
    if Rails.env.production? || Rails.env.staging?
      Communication::Email::MailgunWorker.perform_async(email.id.to_s)
    else
      attachments = {}
      email.attachments.collect do |doc|
        attachments[doc.file_name] = File.read("#{Rails.root}/public/#{doc.file.url}")
      end
      ApplicationMailer.test({
        to: email.recipients.distinct(:email),
        cc: email.cc,
        body: email.body,
        subject: email.subject,
        attachments: attachments
      }).deliver
    end
  end
end
