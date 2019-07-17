module SchemesHelper
  def custom_schemes_path
    current_user.buyer? ? buyer_emails_path : admin_schemes_path
  end
end
