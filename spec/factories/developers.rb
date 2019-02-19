FactoryBot.define do
  factory :developer do
    name { Faker::Name.name }
    selldo_id { Faker::String.random(3..12) }
    after(:build) do |developer|
      developer.booking_portal_client = Client.first if developer.booking_portal_client_id.blank?
      developer.client_id = developer.booking_portal_client.id
    end
  end
end
