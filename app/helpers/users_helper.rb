module UsersHelper

  def get_referral_code
    if current_user.referral_code.blank?
      link_to t('referrals.generate_code.link_name'), generate_code_buyer_referrals_path, method: :post, remote: true, class: 'btn btn-sm btn-default'
    else
      text_field_tag '', current_user.referral_code, readonly: true, class: 'form-control'
    end
  end

  def invite_friend_link
    if policy([:buyer, :referral]).new?
      link_to t('referrals.new.link_name'), new_buyer_referral_path, class: 'btn btn-primary modal-remote-form-link pull-left', data:{ event_category: 'Section', event_action: 'Click', event_name: 'Invite Friend'}
    else
      ''
    end
  end

  def filter_user_role_options
    User.available_roles(current_client).collect{|role| [ t("users.role.#{role}"), role ]}
  end

  def filter_buyer_role_options
    User.buyer_roles(current_client).collect{|role| [ t("users.role.#{role}"), role ]}
  end

  def user_edit_role_options(_user)
    if _user.id == current_user.id
      [[ t("users.role.#{_user.role}"), _user.role]]
    elsif _user.buyer?
      filter_buyer_role_options
    else
      filter_user_role_options
    end
  end
end
