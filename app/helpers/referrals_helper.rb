module ReferralsHelper
  def custom_referrals_path
    current_user.role.in?(%w(cp_owner channel_partner)) ? admin_referrals_path : ''
  end
end
