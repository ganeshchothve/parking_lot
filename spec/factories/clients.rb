
FactoryBot.define  do
  factory :client do

    name { Faker::Company.name }
    selldo_client_id { BSON::ObjectId.from_time(DateTime.now, unique: true).to_s }
    selldo_form_id { BSON::ObjectId.from_time(DateTime.now, unique: true).to_s }
    selldo_channel_partner_form_id { BSON::ObjectId.from_time(DateTime.now, unique: true).to_s }
    selldo_gre_form_id { BSON::ObjectId.from_time(DateTime.now, unique: true).to_s }
    helpdesk_email { Faker::Internet.email }
    helpdesk_number { Faker::Number.number(10) }

    notification_email { Faker::Internet.email }
    notification_numbers { Faker::Number.number(10) }

    support_email { Faker::Internet.email }
    support_number { Faker::Number.number(10) }

    sender_email { Faker::Internet.email }
    email_domains { ['amuratech.com'] }
    booking_portal_domains { ['localhost'] }
    registration_name { Faker::Company.name }
    website_link { 'abc.com' }

    cin_number { Faker::Number.number(12) }
    enable_referral_bonus { true }
    mailgun_private_api_key { 'test' }
    mailgun_email_domain { 'test' }
    sms_provider_username { 'test' }
    sms_provider_password { 'test' }
  end
end
