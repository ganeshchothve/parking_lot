class ClientObserver < Mongoid::Observer
  def before_validation client
    client.enable_communication = {email: true, sms: true, 'whatsapp': false, 'notification': false} if client.enable_communication.blank?
    client.enable_communication[:email] = (client.enable_communication[:email].to_s == "true") || (client.enable_communication[:email].to_s == "1")
    client.enable_communication[:sms] = (client.enable_communication[:sms].to_s == "true") || (client.enable_communication[:sms].to_s == "1")
    client.enable_communication[:whatsapp] = (client.enable_communication[:whatsapp].to_s == "true") || (client.enable_communication[:whatsapp].to_s == "1")
    client.enable_communication[:notification] = (client.enable_communication[:notification].to_s == "true") || (client.enable_communication[:notification].to_s == "1")
  end

  def after_create client
    DatabaseSeeds::EmailTemplates.client_based_email_templates_seed(client.id.to_s)
    DatabaseSeeds::SmsTemplate.client_based_sms_templates_seed(client.id.to_s)
    DatabaseSeeds::UITemplate.client_based_seed(client.id.to_s)
    ExternalInventoryViewConfig.create(booking_portal_client_id: client.id)
    DatabaseSeeds::PortalStagePriorities.seed
    DatabaseSeeds::PortalStagePriorities.channel_partner_seed
    DatabaseSeeds::NotificationTemplate.client_based_seed(client.id.to_s)

    DocumentSign.create(booking_portal_client_id: client.id)
  end

  def after_save client
    fields = ['channel_partners', 'leads']
    fields.each do |field|
      if defined?("enable_#{field}_changed?") && client.send("enable_#{field}_changed?")
        if Rails.env.staging? || Rails.env.production?
          ChangeCpStatus.perform_async(client.id.to_s, client.send("enable_#{field}_changed?"), field)
        else
          ChangeCpStatus.new.perform(client.id.to_s, client.send("enable_#{field}_changed?"), field)
        end
      end
    end
  end
end
