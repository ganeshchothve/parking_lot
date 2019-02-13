FactoryBot.define do
  factory :project_unit do
    name { Faker::Name.name }
    erp_id { Faker::IDNumber.valid }
    agreement_price { Faker::Number.number(6) }
    all_inclusive_price { Faker::Number.number(8) }
    booking_price { Faker::Number.number(5) }
    status { 'available' } # { ['available', 'hold', 'blocked', 'booked_confirmed', 'booked_tentative'].sample }
    available_for { %w[user employee management].sample }
    auto_release_on { Faker::Date.between(2.days.ago, Date.today) }
    base_rate { Faker::Number.number(7).to_f }
    client_id { Faker::IDNumber.valid }
    developer_name { Faker::Name.name }
    project_name { Faker::Name.name }
    project_tower_name { Faker::Name.name }
    unit_configuration_name { Faker::Name.name }
    selldo_id { Faker::String.random(3..12) }
    floor_rise { Faker::Number.number(5).to_f }
    floor { Faker::Number.number(1) }
    floor_order { Faker::Number.number(2) }
    bedrooms { Faker::Number.number(1).to_f }
    bathrooms { Faker::Number.number(1).to_f }
    carpet { Faker::Number.number(4).to_f }
    saleable { Faker::Number.number(4).to_f }
    type { Faker::Lorem.word }

    after(:create) do |project_unit|
      # project_unit.user_kycs ||= ( UserKyc.all.sample.id || create(:user_kyc) )
      # project_unit.selected_scheme_id ||= create(:scheme)
    end

    association :project, factory: :project
    association :developer, factory: :developer
    association :project_tower, factory: :project_tower
    association :unit_configuration, factory: :unit_configuration
    association :booking_portal_client, factory: :client
    # association :user, factory: :user
  end
end
