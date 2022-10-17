class Admin::UserPolicy < UserPolicy
  # def resend_confirmation_instructions? def resend_password_instructions? def export? def update_password? def update? def create? from UserPolicy

  def index?
    !user.buyer?
  end

  def new?(for_edit = false)
    return false unless user
    if user.booking_portal_client.roles_taking_registrations.include?(user.role)
      if user.role?('superadmin')
        (!record.buyer? && !record.role.in?(%w(cp_owner channel_partner)) && !marketplace_portal?) || for_edit
      elsif user.role?('admin')
        !record.role?('superadmin') &&
        (
          (!record.buyer? && !record.role.in?(%w(cp_owner channel_partner)) && !marketplace_portal?) ||
          (marketplace_portal? && record.role?('channel_partner') && user.booking_portal_client.enable_channel_partners?) ||
          for_edit
        )
      elsif user.role?('channel_partner')
        false
      elsif user.role?('cp_owner')
        record.role.in?(%w(cp_owner channel_partner))
      elsif user.role?('sales_admin')
        record.role?('sales') && !marketplace_portal?
      elsif user.role?('cp_admin') && !marketplace_portal?
        record.role?('cp') ||
        (
          record.role.in?(%w(cp_owner channel_partner)) &&
          user.booking_portal_client.enable_channel_partners? &&
          for_edit
        )
      elsif user.role?('cp') && !marketplace_portal?
        (record.role.in?(%w(cp_owner channel_partner)) && user.booking_portal_client.enable_channel_partners? && for_edit)
      elsif user.role?('billing_team')
        false
      elsif !user.buyer?
        false
      end
    else
      false
    end
  end

  def show_add_users_dropdown?
    marketplace_portal? && user.role.in?(%w(admin)) && user.booking_portal_client.enable_channel_partners?
  end

  def edit?
    super || new?(true) || marketplace_portal?
  end

  def confirm_user?
    if %w[admin superadmin].include?(user.role) && !record.confirmed?
      if marketplace_portal?
        if record.role.in?(%w(cp_owner channel_partner))
          Rails.env.production? ? false : true
        else
          record.is_active_in_kylas?
        end
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
    if marketplace_portal? && record.role.in?(%w(cp_owner channel_partner))
      valid = valid && (Rails.env.production? ? false : true)
    end
    valid
  end

  def print?
    record.buyer?
  end

  def portal_stage_chart?
    true
  end

  def asset_create?
    User::BUYER_ROLES.include?(user.role)
  end

  def block_lead?
    record.confirmed? && record.buyer? && record.manager_id.blank? && !record.temporarily_blocked? && %w(sales sales_admin admin).include?(user.role) && !record.iris_confirmation? && record.booking_portal_client.lead_blocking_days.present?
  end

  def unblock_lead?
    record.buyer? && record.temporarily_blocked? && %w(sales sales_admin admin).include?(user.role)
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
    valid = false if marketplace_portal?
    valid
  end

  def change_state?
    (
      user.role.in?(%w(cp_owner)) && user.id != record.id &&
      record.user_status_in_company.in?(%w(active pending_approval)) && user.channel_partner.primary_user.id != record.id
    ) || (
      user.role.in?(%w(cp cp_admin superadmin)) &&
      record.user_status_in_company.in?(%w(pending_approval))
    )
  end

  def update_player_ids?
    user.role.in?(%w(superadmin admin channel_partner cp_owner))
  end

  def sync_kylas_user?
    if user.role?(:superadmin)
      user.selected_client.kylas_tenant_id.present?
    else
      user.booking_portal_client.kylas_tenant_id.present?
    end
  end

  def permitted_attributes(params = {})
    attributes = super
    if user.present?
      if marketplace_portal?
        attributes += [:is_active] if record.persisted? && record.id != user.id && record.is_active_in_kylas? && user.role.in?(%w(admin))
      else
        attributes += [:is_active] if record.persisted? && record.id != user.id && user.role.in?(%w(admin))
      end
      if %w[admin superadmin].include?(user.role)  && record.role?('cp')
        attributes += [:manager_id]
      end
      if %w[admin superadmin cp_admin sales_admin].include?(user.role) && record.buyer?
        # TODO: Lead conflict module with multi project
        #attributes += [:manager_id]
        #attributes += [:manager_change_reason] if record.persisted?
        attributes += [:allowed_bookings] if user.booking_portal_client.allow_multiple_bookings_per_user_kyc?
      end

      attributes += [:premium, :tier_id] if record.role.in?(%w(cp_owner channel_partner)) && user.role?('admin')

      if %w[superadmin admin cp_owner].include?(user.role)
        attributes += [:role] unless record.role?('cp_owner') && record&.channel_partner&.primary_user_id == record.id
      end

      attributes += [project_ids: []] if %w[admin superadmin].include?(user.role) && record.role.in?(User::SELECTED_PROJECT_ACCESS)
      if %w[superadmin admin sales_admin].include?(user.role) && !marketplace_portal?
        attributes += [:erp_id]
        attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
      end
      # To give selected channel partner access of live inventory.
      attributes += [:enable_live_inventory] if user.role?(:superadmin) && record.role?(:channel_partner)
    end # user.present?

    if record.role.in?(%w(cp_owner channel_partner))
      attributes += [:upi_id]
      attributes += [:referral_code] if record.new_record?
      attributes += [:channel_partner_id] if user.present? && user.role.in?(%w(cp_owner admin))
      attributes += [fund_accounts_attributes: FundAccountPolicy.new(user, FundAccount.new).permitted_attributes] if record.persisted?
      attributes += [:rejection_reason]
    end
    attributes += [:login_otp] if confirm_via_otp?
    attributes.uniq
  end
end
