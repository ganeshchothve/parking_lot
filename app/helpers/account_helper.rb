module AccountHelper
  def set_up_account account
    Razorpay.setup(account.key, account.secret)
  end

  def custom_accounts_path
    current_user.buyer? ? '' : admin_accounts_path
  end

  def custom_phases_path
    current_user.buyer? ? '' : admin_phases_path
  end
end