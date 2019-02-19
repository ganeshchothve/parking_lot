FactoryBot.define do
  factory :phase do
    name { Faker::Number.number(2) }
  end
end
