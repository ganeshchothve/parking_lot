class Admin::UserPolicy < UserPolicy
  # def resend_confirmation_instructions? def resend_password_instructions? def export? def update_password? def update? def create? from UserPolicy

  def index?
    !user.buyer?
  end

  def new?(for_edit = false)
    if current_client.roles_taking_registrations.include?(user.role)
      if user.role?('superadmin')
        (!record.buyer? && !record.role?('channel_partner')) || for_edit
      elsif user.role?('admin')
        !record.role?('superadmin') && ((!record.buyer? && !record.role?('channel_partner')) || for_edit)
      elsif user.role?('channel_partner')
        false
      elsif user.role?('sales_admin')
        record.role?('sales')
      elsif user.role?('cp_admin')
        record.role?('cp') || (record.role?('channel_partner') && for_edit)
      elsif user.role?('cp')
        (record.role?('channel_partner') && for_edit)
      elsif user.role?('billing_team')
        false
      elsif !user.buyer?
        false
      end
    else
      false
    end
  end

  def edit?
    super || new?(true)
  end

  def confirm_user?
    if %w[admin superadmin].include?(user.role) && !record.confirmed?
      true
    else
      @condition = 'cannot_confirm_user'
      false
    end
  end

  def reactivate_account?
    %w[admin superadmin].include?(user.role)# && record.expired? because of devise expirable disabled
  end

  def confirm_via_otp?
    !record.confirmed? && record.phone.present? && new? && !user.buyer?
  end

  def print?
    record.buyer?
  end

  def portal_stage_chart?
    true
  end

  def asset_create?
    %w[admin sales sales_admin crm].include?(user.role)
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
    ENV_CONFIG['selldo'].try(:[], 'base_url').present? && record.buyer? && record.lead_id? && current_client.selldo_default_search_list_id?
  end

  def show_lead_tagging?
    %w(admin superadmin).include?(user.role) && user.booking_portal_client.enable_lead_conflicts?
  end

  def channel_partner_performance?
    true
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:is_active] if record.persisted? && record.id != user.id
    if %w[admin superadmin].include?(user.role) && record.role.in?(%w(channel_partner cp))
      attributes += [:manager_id]
    end
    if %w[admin superadmin cp_admin sales_admin].include?(user.role) && record.buyer?
      # TODO: Lead conflict module with multi project
      #attributes += [:manager_id]
      #attributes += [:manager_change_reason] if record.persisted?
      attributes += [:allowed_bookings] if current_client.allow_multiple_bookings_per_user_kyc?
    end
    attributes += [:login_otp] if confirm_via_otp?
    attributes += [:rera_id] if record.role?('channel_partner')
    attributes += [:premium, :tier_id] if record.role?('channel_partner') && user.role?('admin')
    attributes += [:role] if %w[superadmin admin].include?(user.role)
    if %w[superadmin admin sales_admin].include?(user.role)
      attributes += [:erp_id]
      attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
    end
    # To give selected channel partner access of live inventory.
    attributes += [:enable_live_inventory] if user.role?(:superadmin) && record.role?(:channel_partner)
    attributes.uniq
  end
end
