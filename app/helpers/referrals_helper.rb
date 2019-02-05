module ReferralsHelper
  def custom_referrals_path
    current_user.buyer? ? buyer_referrals_path : ''
  end
end