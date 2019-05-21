class ClientObserver < Mongoid::Observer
  def before_save client
    client.enable_communication = {email: true, sms: true} if client.enable_communication.blank?
    client.enable_communication[:email] = (client.enable_communication[:email].to_s == "true") || (client.enable_communication[:email].to_s == "1")
    client.enable_communication[:sms] = (client.enable_communication[:sms].to_s == "true") || (client.enable_communication[:sms].to_s == "1")
  end

  def after_save client
    # Generate time slots for successful direct payments with token number when time_slot_generation is enabled.
    client.set(enable_payment_without_kyc: false) if client.enable_direct_payment
    Receipt.where(booking_detail_id: nil, time_slot: nil).ne(token_number: nil).in(status: %w(clearance_pending success)).each(&:set_time_slot) if client.enable_slot_generation?
  end

  def after_create client
    DatabaseSeeds::SmsTemplate.seed client.id.to_s
    DatabaseSeeds::EmailTemplates.seed client.id.to_s
    Template::CostSheetTemplate.create(name: "Default Cost sheet template", content: Template::CostSheetTemplate.default_content, booking_portal_client_id: client.id, default: true)
    Template::PaymentScheduleTemplate.create(name: "Default payment schedule template", content: Template::PaymentScheduleTemplate.default_content, booking_portal_client_id: client.id, default: true)
    Template::ReceiptTemplate.create(content: Template::ReceiptTemplate.default_content, booking_portal_client_id: client.id)
    Template::AllotmentLetterTemplate.create(content: Template::AllotmentLetterTemplate.default_content, booking_portal_client_id: client.id)
    ExternalInventoryViewConfig.create(booking_portal_client_id: client.id)
  end
end
