class ClientObserver < Mongoid::Observer
  def before_validation client
    client.enable_communication = {email: true, sms: true, 'whatsapp': false} if client.enable_communication.blank?
    client.enable_communication[:email] = (client.enable_communication[:email].to_s == "true") || (client.enable_communication[:email].to_s == "1")
    client.enable_communication[:sms] = (client.enable_communication[:sms].to_s == "true") || (client.enable_communication[:sms].to_s == "1")
    client.enable_communication[:whatsapp] = (client.enable_communication[:whatsapp].to_s == "true") || (client.enable_communication[:whatsapp].to_s == "1")
  end

  def after_save client
    # Generate time slots for successful direct payments with token number when time_slot_generation is enabled.
    Receipt.where(booking_detail_id: nil, time_slot: nil).ne(token_number: nil).in(status: %w(clearance_pending success)).each(&:set_time_slot) if client.enable_slot_generation_changed? && client.enable_slot_generation?
  end

  def after_create client
    DatabaseSeeds::EmailTemplates.client_based_email_templates_seed(client.id.to_s)
    DatabaseSeeds::SmsTemplate.client_based_sms_templates_seed(client.id.to_s)
    DatabaseSeeds::UITemplate.client_based_seed(client.id.to_s)
    ExternalInventoryViewConfig.create(booking_portal_client_id: client.id)
    DatabaseSeeds::PortalStagePriorities.seed
    Template::InvoiceTemplate.seed(client.id.to_s)

    DocumentSign.create(booking_portal_client_id: client.id)
  end
end
