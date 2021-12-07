module ReferralsHelper
  def custom_referrals_path
    current_user.role?("channel_partner") ? admin_referrals_path : ''
  end
end