class ClientObserver < Mongoid::Observer
  def before_save client
    client.enable_communication = {email: true, sms: true} if client.enable_communication.blank?
    client.enable_communication[:email] = (client.enable_communication[:email].to_s == "true") || (client.enable_communication[:email].to_s == "1")
    client.enable_communication[:sms] = (client.enable_communication[:sms].to_s == "true") || (client.enable_communication[:sms].to_s == "1")
  end

  def after_create client
    DatabaseSeeds::SmsTemplate.seed client.id.to_s
    DatabaseSeeds::EmailTemplates.seed client.id.to_s
    Template::CostSheetTemplate.create(content: Template::CostSheetTemplate.default_content, booking_portal_client_id: client.id)
    Template::PaymentScheduleTemplate.create(content: Template::PaymentScheduleTemplate.default_content, booking_portal_client_id: client.id)
    Template::ReceiptTemplate.create(content: Template::ReceiptTemplate.default_content, booking_portal_client_id: client.id)
    Template::AllotmentLetterTemplate.create(content: Template::AllotmentLetterTemplate.default_content, booking_portal_client_id: client.id)
    ExternalInventoryViewConfig.create(booking_portal_client_id: client.id)
  end
end
