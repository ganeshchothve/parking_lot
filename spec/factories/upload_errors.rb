FactoryBot.define do
  factory :upload_error do
    row { [Faker::String.random, Faker::String.random] }
    messages { [Faker::String.random, Faker::String.random] }
  end
end
