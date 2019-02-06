FactoryBot.define do
  factory :unit_configuration do
    selldo_id { Faker::String.random(3..12) }
    is_active { Faker::Boolean.boolean }
    sync_data { Faker::Boolean.boolean }
    promoted { Faker::Boolean.boolean }
    offers { Faker::Boolean.boolean }
    name { Faker::Name.name }
    saleable { Faker::Number.number(5) }
    carpet { Faker::Number.number(5) }
    base_rate { Faker::Number.number(5) }
  end
end
