FactoryBot.define do
  factory :external_api do
    client_api { Faker::Company.name }
    domain { Faker::Internet.domain_name }
  end
end
