FactoryBot.define do
  factory :search do
    bedrooms { Faker::Number.number(1) }
    carpet { Faker::Number.number(8) }
    agreement_price { Faker::Number.number(8) }
    all_inclusive_price { Faker::Number.number(8) }
    floor { Faker::Number.number(2) }
    project_unit_id ''
    project_tower_id ''

    association :user, strategy: :build
  end
end
