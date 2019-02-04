FactoryBot.define do
  factory :user_kyc do
    salutation { ['Mr.', 'Mrs.'].sample }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone }
    dob { Faker::Date.birthday(18, 65) }
    pan_number { Faker::Base.regexify(/[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i) }
    aadhaar { Faker::Base.regexify(/\d{12}/i) }
    anniversary { Faker::Date.between(2.days.ago, Date.today) }
    education_qualification { Faker::Job.education_level }
    designation { Faker::Job.title }
    customer_company_name { Faker::Company.name }
    min_budget { Faker::Number.number(5) }
    max_budget { Faker::Number.number(7) }
    comments { Faker::Lorem.paragraph }
    existing_customer { Faker::Boolean.boolean }
    existing_customer_project { Faker::Lorem.word }
    existing_customer_name { Faker::Name.name }

    association :user, factory: :user
  end
end