FactoryBot.define do
  factory :payment_adjustment do
    name { Faker::Name.name }
    field { 'agreement_price' }
    absolute_value { Faker::Number.number(4) }
    editable true
  end
end
