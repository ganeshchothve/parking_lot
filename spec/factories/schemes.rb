FactoryBot.define do
  factory :scheme do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
    status { 'draft' }
    approved_at { Faker::Date.between(2.days.ago, Date.today) }
    default { Faker::Boolean.boolean }
    can_be_applied_by { [] }
    after(:build) do |scheme|
      scheme.project_tower ||= ProjectTower.desc(:created_at).first
      scheme.project ||= scheme.project_tower.project || create(:project)
      scheme.created_by ||= User.where(role: 'admin').first || create(:admin)
      scheme.booking_portal_client ||= (Client.asc(:created_at).first || create(:client))
    end

    after(:create) do |scheme|
      scheme.payment_adjustments << FactoryBot.build(:payment_adjustment)
    end
  end
end
