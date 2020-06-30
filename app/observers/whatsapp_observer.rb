#
# Class Whatsapp Observer
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
class WhatsappObserver < Mongoid::Observer
  def before_create whatsapp
    whatsapp.to = whatsapp.recipient.phone if whatsapp.to.nil? && whatsapp.recipient_id.present? && whatsapp.recipient.phone.present?
    if whatsapp.whatsapp_template_id.present?
      begin
        whatsapp_template = Template::WhatsappTemplate.find whatsapp.whatsapp_template_id
        whatsapp.content = whatsapp_template.parsed_content(whatsapp.triggered_by)
      rescue => e
        whatsapp.content = ''
      end
    else
      whatsapp.content = TemplateParser.parse(whatsapp.content, whatsapp.triggered_by)
    end
  end

  def after_create whatsapp
    # whatsapp sent when
    # Template Present  |   Templat Is Active  |   ENV in list  |   whatsapp sent or not
    #      T            |          T           |       T        |        yes
    #      T            |          T           |       F        |         no
    #      T            |          F           |       T        |         no
    #      T            |          F           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    if whatsapp.booking_portal_client.whatsapp_enabled?
      if Rails.env.production? || Rails.env.staging?
        Communication::Whatsapp::WhatsappWorker.perform_async(whatsapp.id.to_s)
      else
        whatsapp.set(status: 'sent')
      end
    end
  end

  def before_save whatsapp
    whatsapp.vendor = 'WhatsappNotifier::Haptik' if whatsapp.booking_portal_client.whatsapp_vendor == 'haptik'
  end
end
