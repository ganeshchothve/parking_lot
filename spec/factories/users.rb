FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone { Faker::Base.regexify(/^\d{10}$/) }
    # role { ["user","channel_partner"] }
    allowed_bookings { Faker::Number.number(2) }
    manager_change_reason { Faker::Lorem.paragraph }
    lead_id { Faker::IDNumber.valid }
    rera_id { Faker::IDNumber.valid }
    confirmed_at { DateTime.now }

    association :booking_portal_client, factory: :client

    after(:build) do |user|
      user.booking_portal_client ||= (Client.asc(:created_at).first || create(:client))
    end

    after(:create) do |user|
      user.confirm
      user.booking_portal_client ||= (Client.asc(:created_at).first || create(:client))
    end
  end
  %w[superadmin admin crm employee_user sales_admin sales gre cp cp_admin channel_partner management_user].each do |_role|
    factory _role, parent: :user do
      role { _role }
    end
  end
end
