module UserKycsHelper
  def custom_user_kycs_path
    current_user.buyer? ? buyer_user_kycs_path : admin_user_kycs_path
  end
end
