FactoryBot.define do
  factory :developer do
    name { Faker::Name.name }
    client_id { FactoryBot.create(:client).id }
    booking_portal_client_id { FactoryBot.create(:client).id }
    selldo_id { Faker::String.random(3..12) }
  end
end
