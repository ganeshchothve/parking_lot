module UsersHelper

  def get_referral_code
    if current_user.referral_code.blank?
      link_to t('controller.referrals.generate_code.link_name'), [:generate_code, current_user_role_group, :referrals], method: :post, class: 'btn btn-sm btn-primary'
    else
      text_field_tag '', current_user.referral_code, readonly: true, class: 'referral-code-input border-0 shadow-0 font-medium'
    end
  end

  def invite_friend_link
    if policy([:admin, :referral]).new?
      link_to t('controller.referrals.new.link_name'), new_admin_referral_path, class: 'modal-remote-form-link btn btn-sm btn-primary', data:{ event_category: 'Section', event_action: 'Click', event_name: 'Invite Friend'}
    else
      ''
    end
  end

  def filter_user_role_options client
    User.available_roles(client).collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def filter_admin_role_options
    User::ADMIN_ROLES.collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def filter_project_names_options
    Project.pluck(:name,:id)
  end

  def filter_buyer_role_options client
    User.buyer_roles(client).collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
  end

  def filter_tl_dashboard_access_options
    User::TEAM_LEAD_DASHBOARD_ACCESS_USERS.collect{|role| [User.human_attribute_name("role.#{role}"), role]}
  end

  def marketplace_roles
    if @user.role?('channel_partner')
      %w[channel_partner].collect{|role| [User.human_attribute_name("role.#{role}"), role]}
    elsif @user.role?('cp_owner')
      %w[channel_partner cp_owner].collect{|role| [User.human_attribute_name("role.#{role}"), role]}
    else
      %w[admin sales gre sales_admin].collect{|role| [User.human_attribute_name("role.#{role}"), role]}
    end
  end

  def mandates_roles client
    User.available_roles(client).reject{|role| User.buyer_roles(client).include?(role) || role.in?(%w(cp_owner channel_partner))}.collect{ |r| [User.human_attribute_name("role.#{r}"), r] }
  end

  def filter_roles client
    if marketplace?
      marketplace_roles
    else
      mandates_roles client
    end
  end


  def user_edit_role_options(_user)
    if marketplace?
      marketplace_roles
    else
      if _user.id == current_user.id
      [[ User.human_attribute_name("role.#{_user.role}"), _user.role]]
      elsif _user.buyer?
        filter_buyer_role_options _user.booking_portal_client
      elsif current_user.role?('cp_owner') || _user.role.in?(%w(channel_partner cp_owner))
        %w(cp_owner channel_partner).collect { |x| [User.human_attribute_name("role.#{x}"), x] }
      else
        User.available_roles(_user.booking_portal_client).reject {|x| x.in?(%w(cp_owner channel_partner))}.collect{|role| [ User.human_attribute_name("role.#{role}"), role ]}
      end
    end
  end

  def user_filter_role_options client
    if current_user.role?('cp_owner')
      %w(cp_owner channel_partner).collect { |x| [User.human_attribute_name("role.#{x}"), x] }
    else
      filter_user_role_options client
    end
  end

  def fetch_manager_role(user)
    case user.role
    when *(User::BUYER_ROLES)
      'channel_partner'
    when 'channel_partner', 'cp_owner'
      'cp'
    when 'cp'
      'cp_admin'
    end
  end
end
