FactoryBot.define do
  factory :portal_stage do
    stage { Faker::Subscription.status }
  end
end
