# Create user erp model
client = Client.new(name: "Sukhwani Skylines", selldo_client_id: "", selldo_form_id: "", selldo_gre_form_id: "", selldo_channel_partner_form_id: "", selldo_api_key: "", selldo_default_srd: "", selldo_cp_srd: "", helpdesk_number: "1111111111", helpdesk_email: "abhishek.ghorpade@sell.do", ga_code: "", gtm_tag: "", notification_email: "abhishek.ghorpade@sell.do", notification_numbers: "1111111111", email_domains: ["sell.do"], booking_portal_domains: ["demo.bookingportal.withamura.com"], registration_name: "Sukhwani Skylines", website_link: "www.amuratech.com", cp_disclaimer: "CP Disclaimer", disclaimer: "End User Disclaimer", support_number: "1111111111", support_email: "abhishek.ghorpade@sell.do", sender_email: "abhishek.ghorpade@sell.do", channel_partner_support_number: "1111111111", channel_partner_support_email: "abhishek.ghorpade@sell.do", cancellation_amount: 5000, area_unit: "psqft.", preferred_login: "phone", sms_provider_username: "amuramarketing", sms_provider_password: "aJ_Z-1j4", enable_actual_inventory: ['admin'], enable_channel_partners: false, enable_company_users: true, remote_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png", remote_mobile_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png", allowed_bookings_per_user: 5, cin_number: "CIN1234", mailgun_email_domain: "iris.sell.do", mailgun_private_api_key: 'key-7dq3qw4xmctgtt0rtfyyg6mk3u-g2ke3')
client.save

project = Project.new(name: "Sukhwani Skylines", remote_logo_url: "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png", rera_registration_no: "RERA-AMURA-123", booking_portal_client: client)
project.save


# number = 10000000000
# i = 1
# ['admin'].each do |email_name|
#   %w(superadmin admin crm sales_admin sales user gre cp_admin cp management_user employee_user).each do |role|
#     user = User.new(first_name: email_name.sub('.', ''), last_name: "Amuratech", role: role, booking_portal_client: Client.first, email: "#{email_name}+#{role}@amuratech.com", phone: (number + i), password: "amura123", confirmed_at: DateTime.now )
#     user.skip_confirmation_notification!
#     if user.save
#       i += 1
#       puts "Done - #{user.email}"
#     else
#       puts user.errors.as_json, role, email_name
#     end
#   end
# end

# DatabaseSeeds::ErpModelTemplate.seed
# DatabaseSeeds::SmsTemplate.seed Client.last.id
# DatabaseSeeds::EmailTemplates.seed(Client.first.id)
