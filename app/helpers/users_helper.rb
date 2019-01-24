module UsersHelper

  def get_referral_code
    if current_user.referral_code.blank?
      link_to t('referrals.generate_code.link_name'), generate_code_buyer_referrals_path, method: :post, remote: true, class: 'btn btn-sm btn-default'
    else
      text_field_tag '', current_user.referral_code, readonly: true, class: 'form-control text-right'
    end
  end

  def invite_friend_link
    if policy([:buyer, :referral]).new?
      link_to t('referrals.new.link_name'), new_buyer_referral_path, class: 'btn btn-primary modal-remote-form-link pull-left ml-2 btn-sm', data:{ event_category: 'Section', event_action: 'Click', event_name: 'Invite Friend'}
    else
      ''
    end
  end
end