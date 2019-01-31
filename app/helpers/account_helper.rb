module AccountHelper
  def set_up_account account
    Razorpay.setup(account.key, account.secret) 
  end
end