json.extract! user_kyc, :id, :salutation, :first_name, :last_name, :name
  json.url admin_user_kyc_url(user_kyc, format: :json)
