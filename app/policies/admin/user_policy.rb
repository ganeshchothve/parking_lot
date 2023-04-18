class Admin::UserPolicy < UserPolicy
  # def resend_confirmation_instructions? def resend_password_instructions? def export? def update_password? def update? def create? from UserPolicy

  def index?
    !(user.buyer? || user.role?(:channel_partner))
  end

  def new?(for_edit = false)
    return false unless user
    client = user.booking_portal_client
    if user.role?('superadmin')
      # (!record.buyer? && !record.role.in?(%w(cp_owner channel_partner)) && !marketplace_client?) || for_edit
      if marketplace_client?
        false || for_edit
      else
        true
      end
    elsif user.role?('admin')
      if marketplace_client?
        !record.role?('superadmin') &&
        (
          (!record.buyer? && !record.role.in?(%w(cp_owner channel_partner)) && !marketplace_client?) ||
          (marketplace_client? && record.role?('channel_partner') && user.booking_portal_client.enable_channel_partners?) ||
          for_edit
        )
      else
        !record.role?('superadmin') 
      end
    elsif user.role?('channel_partner')
      false
    elsif user.role?('cp_owner')
      record.role.in?(%w(cp_owner channel_partner)) && user.user_status_in_company.in?(%w(active))
    elsif user.role?('sales_admin')
      !marketplace_client? && (record.role?('sales') || record.role.in?(User::BUYER_ROLES))
    elsif user.role.in?(%w(gre crm sales)) && !marketplace_client?
      for_edit
    elsif user.role?('cp_admin') && !marketplace_client?
      record.role?('cp') ||
      (
        record.role.in?(%w(cp_owner channel_partner)) &&
        user.booking_portal_client.enable_channel_partners? &&
        for_edit
      )
    elsif user.role?('cp') && !marketplace_client?
      (record.role.in?(%w(cp_owner channel_partner)) && user.booking_portal_client.enable_channel_partners? && for_edit)
    elsif user.role?('billing_team')
      false
    elsif !user.buyer?
      false
    end
  end

  def show_add_users_dropdown?
    out = false
    if marketplace_client?
      out = user.role.in?(%w(admin channel_partner cp_owner gre)) && user.booking_portal_client.enable_channel_partners?
    else
      out = !user.role.in?(%w(gre crm sales)) 
    end
    out
  end

  def edit?
    super || new?(true)
  end

  def confirm_user?
    if %w[admin superadmin crm sales gre].include?(user.role) && !record.confirmed?
      if marketplace_client?
        record.kylas_user_id.blank? || record.is_active_in_kylas?
      else
        true
      end
    else
      @condition = 'cannot_confirm_user'
      false
    end
  end

  def add_cp_users?
    user.booking_portal_client.try(:enable_channel_partners?) && user.role.in?(%w(admin))
  end

  def reactivate_account?
    %w[admin superadmin].include?(user.role)# && record.expired? because of devise expirable disabled
  end

  def confirm_via_otp?
    valid = !record.confirmed? && record.phone.present? && new? && !user.buyer?
    if marketplace_client? && record.role.in?(%w(cp_owner channel_partner))
      valid = valid && (Rails.env.production? ? false : true)
    end
    valid
  end

  def print?
    if current_client.real_estate?
      record.buyer?
    else
      false
    end
  end

  def portal_stage_chart?
    true
  end

  def asset_create?
    User::BUYER_ROLES.include?(user.role)
  end

  def block_lead?
    if current_client.real_estate?
      record.confirmed? && record.buyer? && record.manager_id.blank? && !record.temporarily_blocked? && %w(sales sales_admin admin).include?(user.role) && !record.iris_confirmation? && record.booking_portal_client.lead_blocking_days.present?
    else
      false
    end
  end

  def unblock_lead?
    if current_client.real_estate?
      record.buyer? && record.temporarily_blocked? && %w(sales sales_admin admin).include?(user.role)
    else
      false
    end
  end

  def send_payment_link?
    record.buyer?
  end

  def show_selldo_links?
    ENV_CONFIG['selldo'].try(:[], 'base_url').present? && record.buyer? && record.lead_id? && user.booking_portal_client.selldo_default_search_list_id?
  end

  def show_lead_tagging?
    %w(admin superadmin).include?(user.role) && user.booking_portal_client.enable_lead_conflicts?
  end

  def channel_partner_performance?
    true
  end

  def partner_wise_performance?
    true
  end

  def site_visit_project_wise?
    true
  end

  def site_visit_partner_wise?
    true
  end

  def search_by?
    # user.role.in?(%w(team_lead))
    user.role.in?(%w(sales gre team_lead))
  end

  def move_to_next_state?
    valid = false
    valid = (user.role?('team_lead') && (record.buyer? || record.role?('sales'))) ||
      user.role?('sales') && (
        (record.buyer? && record.may_dropoff? && (record.closing_manager_id == user.id)) ||
        (!record.is_a?(Lead) && record.role?('sales') && (record.may_break? || record.may_available?))
    )
    valid = false if marketplace_client?
    valid
  end

  def change_state?
    (
      user.role.in?(%w(cp_owner)) && user.id != record.id &&
      record.user_status_in_company.in?(%w(active)) && user.channel_partner.primary_user.id != record.id
    ) || (
      user.role.in?(%w(cp cp_admin superadmin admin)) &&
      record.user_status_in_company.in?(%w(pending_approval))
    )
  end

  def approve_reject_company_user?
    user.role?('cp_owner') && record.user_status_in_company == 'pending_approval' && record.temp_channel_partner_id == user.channel_partner_id
  end

  def update_player_ids?
    user.role.in?(%w(superadmin admin channel_partner cp_owner))
  end

  def sync_kylas_user?
    marketplace_client? && user.role.in?(%w(superadmin admin))
  end

  def show_index?
    user.role.in?(%w(channel_partner cp_owner gre crm sales_admin sales) + User::ALL_PROJECT_ACCESS)
  end

  def note_create?
    unless marketplace_client?
      update?
    else
      false
    end
  end

  def permitted_attributes(params = {})
    attributes = super
    if user.present?
      if marketplace_client?
        attributes += [:is_active] if record.persisted? && record.id != user.id && record.is_active_in_kylas? && user.role.in?(%w(admin))
      else
        attributes += [:is_active] if record.persisted? && record.id != user.id && user.role.in?(%w(admin))
      end
      if %w[admin superadmin].include?(user.role) && record.role?('cp')
        attributes += [:manager_id]
      end
      if %w[admin superadmin cp_admin sales_admin].include?(user.role) && record.buyer?
        # TODO: Lead conflict module with multi project
        #attributes += [:manager_id]
        #attributes += [:manager_change_reason] if record.persisted?
        attributes += [:allowed_bookings]
      end

      attributes += [:premium, :tier_id] if record.role.in?(%w(cp_owner channel_partner)) && user.role?('admin') && current_client.real_estate?

      if %w[superadmin admin cp_owner].include?(user.role)
        attributes += [:role] unless (record.role?('cp_owner') && record&.channel_partner&.primary_user_id == record.id) || user.id == record.id
      end

      attributes += [project_ids: []] if %w[admin superadmin cp_owner].include?(user.role) && !record.role.in?(User::ALL_PROJECT_ACCESS)
      if %w[superadmin admin sales_admin].include?(user.role) && !marketplace_client?
        attributes += [:erp_id]
        attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
      end
      # To give selected channel partner access of live inventory.
      attributes += [:enable_live_inventory] if user.role?(:superadmin) && record.role?(:channel_partner) && current_client.real_estate?
    end # user.present?

    if record.role.in?(%w(cp_owner channel_partner))
      attributes += [:upi_id]
      attributes += [:referral_code] if record.new_record?
      attributes += [:channel_partner_id] if user.present? && user.role.in?(%w(cp_owner admin))
      if current_client.real_estate?
        attributes += [fund_accounts_attributes: FundAccountPolicy.new(user, FundAccount.new).permitted_attributes] if record.persisted? && record.user_status_in_company.in?(%w(active))
      end
      attributes += [:rejection_reason]
    end
    attributes += [:user_status_in_company_event] if user.present? && user.role?('cp_owner') && record.user_status_in_company == 'pending_approval' && record.temp_channel_partner_id == user.channel_partner_id
    attributes += [:login_otp] if confirm_via_otp?
    attributes.uniq
  end
end
