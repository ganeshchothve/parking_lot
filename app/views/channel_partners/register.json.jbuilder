json.user do
  json.extract! @user, :_id, :channel_partner_id, :cp_code, :created_at, :email, :phone, :first_name, :last_name, :name, :manager_id, :referral_code, :referred_by_id, :referred_on, :role, :time_zone, :tier_id, :upi_id, :user_status_in_company
end

unless @otp_sent_status[:status]
  errors = [@otp_sent_status[:error]].flatten
  json.errors errors
end
