FactoryBot.define do
  factory :sms do
    to { [Faker::PhoneNumber.cell_phone] }
    body { Faker::String.random(3) }
    sent_on { Faker::Time.between(DateTime.now - 1, DateTime.now) }

    association :recipient, factory: :user
    status { 'scheduled' }

    before(:create) do |sms|
      sms.triggered_by = create(:receipt, user: sms.recipient)
      sms.booking_portal_client = Client.first
    end
  end
end
