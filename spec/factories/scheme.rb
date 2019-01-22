FactoryBot.define do
  factory :scheme do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
    status { %w[approved draft disabled].sample }
    approved_at { Faker::Date.between(2.days.ago, Date.today) }
    # payment_schedule_template_id { FactoryBot.create(:payment_schedule_template).id }
    # cost_sheet_template_id { FactoryBot.create(:cost_sheet_template).id }
    default { Faker::Boolean.boolean }
    can_be_applied_by { [] }
    # project {FactoryBot.create(:project)}
    after(:build) do |scheme|
      scheme.project = FactoryBot.create(:project)
      project_tower = FactoryBot.create(:project_tower, project: project)
      scheme.project_tower_id = project_tower.id
      # user = FactoryBot.create(:user)
      # scheme.set(user_id: user.id)
      # scheme.set(user_role: user.role)
    end

    association :approved_by, factory: :user
    association :created_by, factory: :user
    association :booking_portal_client, factory: :client
    # association :user, factory: :user
  end
end
