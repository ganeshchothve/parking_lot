FactoryBot.define do
  factory :developer do
    name { Faker::Name.name }
    selldo_id { Faker::String.random(3..12) }
    after(:build) do |developer|
      developer.booking_portal_client = Client.first || create(:client)
    end
  end
end
