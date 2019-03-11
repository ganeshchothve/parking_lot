FactoryBot.define do
  factory :sms do
    to { [Faker::PhoneNumber.cell_phone] }
    body { Faker::String.random(3) }
    sent_on { Faker::Time.between(DateTime.now - 1, DateTime.now) }
    status "scheduled"
     before(:create) do |sms| 
      sms.recipient_id ||= User.first.id || create(:user).id
      sms.triggered_by = Receipt.first || create(:receipt)
      sms.booking_portal_client = Client.first
    end
  end
end
 
  