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

    after(:build) do |project_unit|
      project_unit.booking_portal_client = Client.first
      project_unit.developer = create(:developer) 
      project_unit.project_tower = ProjectTower.first
      if ProjectTower.first == nil
        project_unit.project_tower = create(:project_tower)
      end
      project_unit.project = Project.first
      project_unit.unit_configuration = create(:unit_configuration)
    end
  end
end