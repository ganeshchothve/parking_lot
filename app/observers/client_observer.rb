class ClientObserver < Mongoid::Observer
  def before_save client
    Template::CostSheetTemplate.create(content: Template::CostSheetTemplate.default_content, booking_portal_client_id: client.id)
    Template::PaymentScheduleTemplate.create(content: Template::PaymentScheduleTemplate.default_content, booking_portal_client_id: client.id)
    Template::ReceiptTemplate.create(content: Template::ReceiptTemplate.default_content, booking_portal_client_id: client.id)
    Template::AllotmentLetterTemplate.create(content: Template::AllotmentLetterTemplate.default_content, booking_portal_client_id: client.id)
  end
end
