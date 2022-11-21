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
          ChangeCpStatus.perform_async(client.id.to_s, field)
        else
          ChangeCpStatus.new.perform(client.id.to_s, field)
        end
      end
    end
    if client.enable_channel_partners_changed? && client.enable_channel_partners? && client.kylas_custom_fields.blank?
      cp_users = User.in(role: %w[channel_partner cp_owner]).where(user_status_in_company: 'active', booking_portal_client_id: client.id)
      if cp_users.present?
        cp_users.each do |cp_user|
          if Rails.env.production?
            Kylas::PushCustomFieldsToKylas.perform_async(cp_user.id.to_s)
          else
            Kylas::PushCustomFieldsToKylas.new.perform(cp_user.id.to_s)
          end
        end
      else
        user = (client.users.admin.first rescue nil)
        if user.present?
          User::KYLAS_CUSTOM_FIELDS_ENTITIES.each do |entity|
            Kylas::CreateCustomField.new(user, nil, {entity: entity}).call
          end
        end
      end
    end

    if client.is_marketplace? && client.kylas_api_key_was.blank? && client.kylas_api_key.present?
      # syncing kylas products and users into IRIS if flag(is_able_sync_products_and_users) on client is set to true
      if client.try(:is_able_sync_products_and_users?)
        client.set(sync_product: false)
        SyncKylasProductsWorker.perform_async(client.id.to_s)
        client.set(sync_user: false)
        SyncKylasUsersWorker.perform_async(client.id.to_s)
        client.set(is_able_sync_products_and_users: false)

        # Configure Kylas respective Crm Base and Apis for newer clients
        DatabaseSeeds::CrmBase::Kylas.seed(client.id.to_s)
        crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: client.id).first
        DatabaseSeeds::CrmApis.seed(crm_base.id.to_s) if crm_base.present?

        # create a user webhook in Kylas when flag(can_create_webhook) on client is set to true
        if client.can_create_webhook?
          Kylas::CreateWebhook.new(client, {run_in_background: true}).call
          client.set(can_create_webhook: false)
        end
      end
    end
  end
end
