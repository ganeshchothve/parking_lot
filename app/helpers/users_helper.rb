module UsersHelper

  def get_referral_code
    if current_user.referral_code.blank?
      link_to t('referrals.generate_code.link_name'), generate_code_buyer_referrals_path, method: :post, remote: true, class: 'btn btn-sm btn-default'
    else
      text_field_tag '', current_user.referral_code, readonly: true, class: 'form-control col-3 float-right'
    end
  end

  def invite_friend_link
    if policy([:admin, :referral]).new?
      link_to t('controller.referrals.new.link_name'), new_admin_referral_path, class: ' modal-remote-form-link', data:{ event_category: 'Section', event_action: 'Click', event_name: 'Invite Friend'}
    else
      ''
    end
  end

  def filter_user_role_options
    User.available_roles(current_client).collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def filter_admin_role_options
    User::ADMIN_ROLES.collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def filter_project_names_options
    Project.pluck(:name,:id)
  end

  def filter_buyer_role_options
    User.buyer_roles(current_client).collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def user_edit_role_options(_user)
    if _user.id == current_user.id
      [[ User.human_attribute_name("role.#{_user.role}"), _user.role]]
    elsif _user.buyer?
      filter_buyer_role_options
    else
      filter_user_role_options
    end
  end

  def fetch_manager_role(user)
    case user.role
    when *(User::BUYER_ROLES)
      'channel_partner'
    when 'channel_partner'
      'cp'
    when 'cp'
      'cp_admin'
    end
  end
end
