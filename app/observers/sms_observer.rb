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
  end

  def after_create sms
    # SMS sent when
    # Template Present  |   Templat Is Active  |   ENV in list  |   SMS sent or not
    #      T            |          T           |       T        |        yes
    #      T            |          T           |       F        |         no
    #      T            |          F           |       T        |         no
    #      T            |          F           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    if sms.booking_portal_client.sms_enabled?
      if Rails.env.production? || Rails.env.staging?
        if sms.sms_template
          if sms.sms_template.name == 'otp'
            Communication::Sms::SmsjustWorker.set(queue: 'otp').perform_async(sms.id.to_s)
          elsif sms.sms_template.is_active?
            Communication::Sms::SmsjustWorker.perform_async(sms.id.to_s)
          end
        else
          Communication::Sms::SmsjustWorker.perform_async(sms.id.to_s)
        end
      else
        sms.set(status: "sent")
      end
    end
  end

end
