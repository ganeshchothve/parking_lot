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
    if client.enable_channel_partners.changed? && client.enable_channel_partners?
      User.in(role: %w[channel_partner cp_owner]).where(user_status_in_company: 'active', booking_portal_client_id: client.id).each do |cp_user|
        if Rails.env.production?
          Kylas::PushCustomFieldsToKylas.perform_async(cp_user.id.to_s)
        else
          Kylas::PushCustomFieldsToKylas.new.perform(cp_user.id.to_s)
        end
      end
    end
  end
end
