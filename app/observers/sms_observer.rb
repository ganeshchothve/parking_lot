class SmsObserver < Mongoid::Observer

  def before_create sms
    if sms.sms_template_id.present?
      sms_template = SmsTemplate.find sms.sms_template_id
      sms.body = TemplateParser.parse sms_template.content, sms.triggered_by
    else
      sms.body = TemplateParser.parse sms.body, sms.triggered_by
    end
    sms.sent_on = Time.now
  end

  def after_create sms
    if Rails.env.production? || Rails.env.staging?
      SmsWorker.perform_async(sms.id.to_s)
    else
      sms.set(status: "sent")
    end
  end

end
