FactoryBot.define do
  factory :project_tower do
    name { Faker::Name.name }
    client_id { FactoryBot.create(:client).id }
    project_name { Faker::Name.name }
    total_floors { Faker::Number.number(2) }
    total_builtup_area { Faker::Number.number(6).to_f }
    units_per_floor { Faker::Number.number(2).to_f }
    maintenance { Faker::Number.number(4).to_f }
    rate { Faker::Number.number(5).to_f }
    total_plot_area { Faker::Number.number(5).to_f }
    floor_rise_rate { Faker::Number.number(5).to_f }
    possession_date { Faker::Date.between(2.days.ago, Date.today) }
    completion_date { Faker::Date.between(2.days.ago, Date.today) }
    project_tower_status { 'completed' }
    selldo_id { Faker::String.random(3..12) }
    completed_floor { Faker::Number.number(2) }
    project_tower_stage { 'completed' }

    after(:build) do |project_tower|
      project_tower.project = Project.desc(:created_at).first || create(:project)
    end
  end
end
