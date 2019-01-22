module UsersHelper

  def get_referral_code
    if current_user.referral_code.blank?
      link_to(t('referrals.generate_code.link_name'), generate_code_buyer_referrals_path, method: :post, remote: true class: 'btn btn-sm btn-default' )
    else
      current_user.referral_code
    end
  end
end