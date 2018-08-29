class SmsObserver < Mongoid::Observer
  def before_create sms
    sms.to ||= []
    sms.to += [sms.recipient.phone] if sms.recipient_id.present? && sms.recipient.phone.present?
    if sms.sms_template_id.present?
      begin
        sms_template = Template::SmsTemplate.find sms.sms_template_id
        sms.body = sms_template.parsed_content(sms.triggered_by)
      rescue => e
        sms.body = ""
      end
    else
      sms.body = TemplateParser.parse(sms.body, sms.triggered_by)
    end
    sms.sent_on = Time.now
  end

  def after_create sms
    if Rails.env.production? || Rails.env.staging?
      Communication::Sms::SmsjustWorker.perform_async(sms.id.to_s)
    else
      sms.set(status: "sent")
    end
  end

end
