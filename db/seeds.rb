#
# Usage:
#   bundle exec rake db:seed client_name='Sukhwani Agarwal Group' project_name='Empire Square' rera_no='RERA-AMURA-123'
#
client = Client.first || Client.new(
  name: (ENV['client_name'].presence || 'Amura'),
  selldo_client_id: "",
  selldo_form_id: "",
  selldo_gre_form_id: "",
  selldo_channel_partner_form_id: "",
  selldo_api_key: "",
  selldo_default_srd: "",
  selldo_cp_srd: "",
  helpdesk_number: "1111111111",
  helpdesk_email: "abhishek.ghorpade@sell.do",
  ga_code: "",
  gtm_tag: "",
  notification_email: "abhishek.ghorpade@sell.do",
  notification_numbers: "1111111111",
  email_domains: ["sell.do"],
  booking_portal_domains: (ENV['booking_portal_domains'].present? ? ENV['booking_portal_domains'].split(',').compact : ["bookingportal.withamura.com"]),
  registration_name: (ENV['client_name'].presence || 'Amura'),
  website_link: "http://www.amuratech.com",
  cp_disclaimer: "CP Disclaimer",
  disclaimer: "End User Disclaimer",
  support_number: "1111111111",
  support_email: "abhishek.ghorpade@sell.do",
  sender_email: "abhishek.ghorpade@sell.do",
  channel_partner_support_number: "1111111111",
  channel_partner_support_email: "abhishek.ghorpade@sell.do",
  cancellation_amount: 5000,
  area_unit: "psqft.",
  preferred_login: "phone",
  sms_provider_username: "amuramarketing",
  sms_provider_password: "aJ_Z-1j4",
  enable_actual_inventory: ['superadmin'],
  enable_channel_partners: false,
  enable_company_users: true,
  remote_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png",
  remote_mobile_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png",
  allowed_bookings_per_user: 5,
  cin_number: "CIN1234",
  mailgun_email_domain: "iris.sell.do",
  mailgun_private_api_key: 'key-7dq3qw4xmctgtt0rtfyyg6mk3u-g2ke3'
)

if client.new_record?
  client.save
else
  attrs = {}
  if ENV['client_name'].present?
    attrs[:name] = ENV['client_name']
    attrs[:registration_name] = ENV['client_name']
  end
  attrs[:booking_portal_domains] = ENV['booking_portal_domains'].split(',').compact if ENV['booking_portal_domains'].present?

  client.update(attrs) if attrs.present?
end

developer = Developer.where(name: client.name, booking_portal_client_id: client.id).first
if developer.blank?
  developer = Developer.create(name: client.name,booking_portal_client_id: client.id)
end

if User.count.zero?
  number = 1000000000
  i = 1
  ['ketan.vaze', 'milan.patel'].each do |email_name|
    %w(superadmin).each do |role|
      user = User.new(first_name: email_name.split('.').first, last_name: email_name.split('.').last, role: role, booking_portal_client: Client.first, email: "#{email_name}@sell.do", phone: (number + i), password: "Amura@123", password_confirmation: 'Amura@123', confirmed_at: DateTime.now )
      user.skip_confirmation_notification!
      if user.save
        i += 1
        puts "Done - #{user.email}"
      else
        puts user.errors.as_json, role, email_name
      end
    end
  end
end

project_name = ENV['project_name'].presence || 'Amura Towers'
project = Project.where(name: project_name).first || Project.new(
  name: project_name,
  remote_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png",
  rera_registration_no: (ENV['rera_no'].presence || "RERA-AMURA-123"),
  booking_portal_client: client,
  developer: developer,
  creator: User.where(role: 'superadmin').first
)

if project && project.new_record?
  project.save
else
  attrs = {}
  attrs[:name] = ENV['project_name'] if ENV['project_name'].present?
  attrs[:rera_registration_no] = ENV['rera_no'] if ENV['rera_no'].present?

  project.update(attrs) if attrs.present?
end
