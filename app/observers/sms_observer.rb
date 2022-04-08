class SmsObserver < Mongoid::Observer
  def before_create sms
    sms.to ||= []
    if sms.recipient_id.present?
      if sms.recipient.phone.present?
        sms.to += [sms.recipient.phone]
      elsif sms.recipient.class == Lead && sms.recipient.user.try(:phone).present?
        sms.to += sms.recipient.user.phone
      end
    end
    if sms.sms_template_id.present? && sms_template = Template::SmsTemplate.where(id: sms.sms_template_id).first
      begin
        sms.body = sms_template.parsed_content(sms.triggered_by)
      rescue => e
        sms.body = ""
      end
      begin
        sms.variable_list = sms_template.template_variables.map{ |v| {id: v.number, value: v.value(sms.triggered_by)} }.compact
      rescue => e
        sms.variable_list = []
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
        worker = Object.const_get("Communication::Sms::#{sms.booking_portal_client.sms_provider.try(:classify) || 'SmsJust'}Worker")
        if sms.sms_template
          if sms.sms_template.name == 'otp'
            worker.new.perform(sms.id.to_s)  # Send OTPs inline
          elsif sms.sms_template.is_active?
            worker.perform_async(sms.id.to_s)
          end
        else
          worker.perform_async(sms.id.to_s)
        end
      else
        sms.set(status: "sent")
      end
    end
  end

end
