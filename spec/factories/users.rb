FactoryBot.define  do
  factory :user do
    first_name { Faker::Name.first_name }
    phone { Faker::Number.number(10) }
    confirmed_at { DateTime.now }

    after(:build) do |user|
      user.booking_portal_client = Client.first if user.booking_portal_client_id.blank?
    end
  end

  %w(superadmin admin crm employee_user sales_admin sales gre cp cp_admin channel_partner management_user).each do |_role|
    factory _role, parent: :user do
      role { _role }
    end
  end
end
