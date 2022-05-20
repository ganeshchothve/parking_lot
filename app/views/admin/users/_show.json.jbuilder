json.(user, :_id, :authentication_token, :channel_partner_id, :confirmed_by_id, :cp_code, :created_at, :email, :phone, :expired_at, :name, :first_name, :last_name, :incentive_generated, :last_otp_sent_at, :manager_change_reason, :manager_id, :premium, :referral_code, :referred_by_id, :referred_on, :register_in_cp_company_token, :rera_id, :role, :portal_stages, :tier_id, :fund_accounts, :user_status_in_company, :rejection_reason)

json.temp_channel_partner_name user.temp_channel_partner&.company_name

if user.role.in?(['cp_owner', 'channel_partner'])
  json.channel_partner({})
  json.channel_partner do
    json.partial! "channel_partners/show", channel_partner: user.channel_partner
  end

  json.manager do
    json.name user.manager&.name
    json.phone user.manager&.phone
    json.email user.manager&.email
  end

  json.helpdesk_number user.booking_portal_client&.channel_partner_support_number
  json.helpdesk_email user.booking_portal_client&.channel_partner_support_email
end
