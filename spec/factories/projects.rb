FactoryBot.define do
  factory :project do
    name { Faker::Name.name }
    developer_name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    lat { Faker::Number.number.to_s }
    lng { Faker::Number.number.to_s }
    possession { Faker::Date.between(2.days.ago, Date.today) }
    is_active { Faker::Boolean.boolean }
    is_whitelabelled { Faker::Boolean.boolean }
    whitelabel_name { Faker::Name.name }
    construction_status { ['na', 'plinth', 'excavation', '3rd floor', '5th floor', '8th floor', 'completed'].sample }
    available_for_transaction { %w[sell lease either].sample }
    launched_on { Faker::Date.between(100.days.ago, 50.days.ago) }
    expected_completion { Faker::Date.between(1.days.ago, Date.today) }
    total_buildings { Faker::Number.number(1) }
    type { %w[residential commercial either].sample }
    commencement_certificate { Faker::Boolean.boolean }
    approved_banks { %w[HDFC KOTAK BOA SBI] }
    suitable_for { %w[IT Manufacturing Investors].sample }
    parking { ['na', 'closed garage', 'stilt', 'podium', 'open'] }
    fire_fighting { Faker::Boolean.boolean }
    comments { Faker::Lorem.sentence }
    external_report { Faker::Lorem.sentence }
    vastu { Faker::Lorem.sentence }
    loading { Faker::Number.number.to_f }
    lock_in_period { Faker::Number.number.to_s }
    approval { Faker::Lorem.paragraph }
    selldo_id { Faker::String.random(3..12) }
    project_pre_sale_ids { [Faker::IDNumber.valid, Faker::IDNumber.valid] }
    project_sale_ids { [Faker::IDNumber.valid, Faker::IDNumber.valid] }
    locality { Faker::Address.street_name }
    total_units { Faker::Number.number }
    apartment_size { Faker::Number.number(4).to_s }
    sync_data { Faker::Boolean.boolean }
    hide_cost_on_portal { %w[yes no].sample }
    dedicated_project_phone {  Faker::Base.regexify(/^\d{10}$/) }
    city { Faker::Address.city }
    rera_registration_no { Faker::IDNumber.valid }

    after(:build) do |project|
      project.booking_portal_client ||= Client.desc(:created_at).first
      project.client_id = Client.desc(:created_at).first.id
      project.developer_id ||= ( Developer.first || create(:developer) )
    end

  end
end
