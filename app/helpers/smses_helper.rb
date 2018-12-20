module SmsesHelper
  def custom_smses_path
    current_user.buyer? ? buyer_smses_path : admin_smses_path
  end
end
