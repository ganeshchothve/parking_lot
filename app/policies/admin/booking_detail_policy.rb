class Admin::BookingDetailPolicy < BookingDetailPolicy

  def index?
    if current_client.real_estate?
      out = %w[admin superadmin sales sales_admin cp cp_admin gre channel_partner cp_owner dev_sourcing_manager crm].include?(user.role) && enable_actual_inventory?(user)
      out = false if user.role.in?(%w(cp_owner channel_partner)) && !interested_project_present?
      out = true if %w[account_manager account_manager_head billing_team cp_admin].include?(user.role)
      out
    else
      false
    end
  end

  def new?(current_project_id = nil)
    valid = true
    unless eligible_user?
      valid = false
      @condition = 'kyc_required'
    end
    unless is_buyer_booking_limit_exceed?
      valid = false
      @condition = 'allowed_bookings'
    end
    if user.role.in?(%w(cp_owner channel_partner))
      if !interested_project_present?
        valid = false
        @condition = 'project_not_subscribed'
      end
    end
    unless project_access_allowed?(current_project_id)
      valid = false
      @condition = 'project_access_not_given'
    end
    unless (%w[superadmin admin sales sales_admin gre] + User::CHANNEL_PARTNER_USERS).include?(user.role)
      valid = false
      @condition = 'user_not_included'
    end
    if record.lead.project.enable_inventory?
      unless record.lead.project.enable_inventory? && enable_actual_inventory?(user)
        valid = false
        @condition = 'inventory_access_not_given'
      end
    end
    unless record.lead&.project&.bookings_enabled?
      valid = false
      @condition = 'booking_disabled_on_project'
    end
    unless record.project&.is_active?
      valid = false
      @condition = 'project_not_active'
    end
    valid
  end

  def create?(current_project_id = nil)
    new?
  end

  def booking?
    true
  end

  def edit?
    record.project&.is_active? && enable_actual_inventory?(user) && (!record.try(:project).try(:booking_with_kyc_enabled?) || record.try(:user).try(:user_kycs).present?)
  end

  def update?
    edit?
  end

  def tasks?
    record.project&.is_active? && %w[cancelled swapped].exclude?(record.status) && (eligible_users_for_tasks? || enable_incentive_module?(user))
  end

  def mis_report?(embedded_marketplace = false)
    return false if embedded_marketplace
    unless marketplace_client?
      %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
    else
      %w[superadmin admin crm cp_admin billing_team cp].include?(user.role)
    end
  end

  def filter?(embedded_marketplace = false)
    return false if embedded_marketplace
    true
  end

  def hold?
    record.project&.is_active? && _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed?
  end

  def send_payment_link?
    valid = if user.booking_portal_client.payment_enabled?
      if user.booking_portal_client.kyc_required_for_payment?
        record.lead.kyc_ready?
      else
        true
      end
    else
      false
    end
    valid = valid && record.user.confirmed? && user.role.in?(User::ADMIN_ROLES) && record.status.in?(BookingDetail::BOOKING_STAGES - %w(booked_confirmed))
    valid && record.project.try(:booking_portal_domains).present?
  end

  def new_booking_on_project?
    return false if marketplace_client?
    enable_actual_inventory? && record.lead&.project&.bookings_enabled? && enable_inventory?
  end

  def show_booking_link?(current_project_id = nil)
    if current_client.real_estate?
      valid = record.lead&.project&.bookings_enabled? && _role_based_check && only_for_confirmed_user! && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed? && record.try(:user).try(:buyer?) && enable_inventory? && enable_actual_inventory?
      # if is_assigned_lead?
      #   valid = is_lead_accepted? && valid
      # end

      valid &&= record.site_visit.conducted? if record.site_visit.present?
      valid &&= !record.lead&.kyc_required_before_booking?
      valid &&= project_access_allowed?(current_project_id)

      valid
    else
      false
    end
  end

  def show_add_booking_link?(current_project_id = nil)
    if current_client.real_estate?
      out = !enable_inventory? && record.try(:user).try(:buyer?) && record.lead&.project&.bookings_enabled? && enable_actual_inventory?
      out = false if user.role.in?(%w(cp_owner channel_partner)) && !(user.active_channel_partner? && interested_project_present?)

      out &&= record.site_visit.conducted? if record.site_visit.present?
      out &&= project_access_allowed?(current_project_id)

      out
    else
      false
    end
  end

  def enable_inventory?
    lead = record.lead
    out = false
    out = true if lead.project.is_active? && lead.project.enable_inventory
    return out
  end

  def send_under_negotiation?
    hold?
  end

  def send_blocked?
    hold?
  end

  def block?
    hold?
  end

  def doc?
    user.active_channel_partner?
  end

  def status_chart?
    user.active_channel_partner?
  end

  def move_to_next_state?
    %w[account_manager account_manager_head cp_admin admin].include?(user.role)
  end

  def move_to_next_approval_state?
    %w[dev_sourcing_manager channel_partner cp_owner cp_admin admin].include?(user.role)
  end

  def reject?
    user.role.in?(%w(dev_sourcing_manager cp_admin admin)) && record.verification_pending?
  end

  def can_move_booked_tentative?
    record.agreement_date.present? && move_to_next_state? && record.blocked? && record.approval_status == "approved"
  end

  def can_move_booked_confirmed?
    (user.role.in?(%w(account_manager_head cp_admin dev_sourcing_manager billing_team admin))) && record.booked_tentative? && record.approval_status == "approved"
  end

  def can_move_cancel?
    out = false
    out = true if (record.booked_tentative? || record.blocked?) && %w(billing_team admin).include?(user.role)
    out = true if (record.booked_tentative? || record.blocked?) && (record.approval_status == "rejected") && %w(cp_admin admin).include?(user.role)
    out
  end

  def send_booking_detail_form_notification?
    user.active_channel_partner?
  end

  def edit_booking_without_inventory?(current_project_id = nil)
    out = false
    out = true if record.status.in?(%w(blocked booked_tentative)) && user.role.in?(%w(account_manager account_manager_head cp_admin))
    out = true if record.approval_status.in?(%w(pending rejected)) && record.status.in?(%w(blocked)) && user.role.in?(%w(cp_owner channel_partner))
    out = out && project_access_allowed?(current_project_id)
    # out = true if %w('booked_tentative', 'booked_confirmed') && user.role?('billing_team')
    out
  end

  def asset_create?
    %w[admin sales_admin sales account_manager account_manager_head billing_team cp_admin cp_owner channel_partner crm].include?(user.role)
  end

  def asset_destroy?
    %w[admin account_manager account_manager_head billing_team cp_admin cp_owner channel_partner].include?(user.role)
  end

  def asset_update?
    asset_create?
  end

  def enable_channel_partners?
    record.booking_portal_client.try(:enable_channel_partners?)
  end

  # def block?
  #   valid = enable_actual_inventory? && only_for_confirmed_user! && only_for_kyc_added_users! && ['hold'].include?(record.status)
  #   if !valid
  #     return
  #   end
  #   valid = (valid && record.user.allowed_bookings > record.user.booking_details.ne(status: 'cancelled').count)
  #   if !valid
  #     @condition = "allowed_bookings"
  #     return
  #   end
  #   _role_based_check
  # end

  def permitted_attributes
    attributes = super
    attributes += [:project_tower_name, :agreement_price, :channel_partner_id, :project_unit_configuration, :booking_project_unit_name, :booked_on, :project_id, :primary_user_kyc_id, :project_unit_id, :user_id, :creator_id, :manager_id, :account_manager_id, :lead_id, :source, user_kyc_ids: []] if record.new_record? || (user.role.in?(%w(cp_owner channel_partner account_manager_head)) && record.status == 'blocked')

    attributes += [:approval_event] if record.approval_status.in?(%w(pending)) && user.role.in?(%w(dev_sourcing_manager cp_admin admin)) && record.blocked?

    attributes += [:approval_event] if record.approval_status.in?(%w(rejected)) && user.role.in?(%w(cp_owner channel_partner admin)) && record.blocked?

    attributes += [:rejection_reason] if user.role.in?(%w(dev_sourcing_manager admin))

    attributes += [:agreement_date]
    if eligible_users_for_tasks?
      attributes += [tasks_attributes: Admin::TaskPolicy.new(user, Task.new).permitted_attributes]
    end
    unless %w(channel_partner cp_owner).include?(user.role)
      attributes += [:other_costs]
    end
    attributes.uniq
  end

  private

  def eligible_users_for_tasks?
    enable_actual_inventory?(user) && !user.role.in?(['gre', 'sales_admin'])
    #return true if %w[admin channel_partner sales_admin sales].include?(user.role)
  end

  def need_unattached_booking_receipts_for_channel_partner
    if user.role.in?(['channel_partner', 'cp_owner'])
      return true if record.lead.unattached_blocking_receipt(record.project_unit.blocking_amount).present?
      @condition = "blocking_amount_receipt"
      false
    else
      true
    end
  end

  def _role_based_check
    if %w[cp sales sales_admin cp_admin admin superadmin].include?(user.role)
      if record.hold?
        true
      elsif record.status.in?(BookingDetail::BOOKING_STAGES)
        @condition = 'booking_done'
        false
      else
        @condition = 'record_not_held'
        false
      end
    elsif (user.role.in?(%w(cp_owner channel_partner)) && record.status == 'hold')
      return true if record.lead.lead_managers.where(user_id: user.id).present? && user.active_channel_partner?
      @condition = 'not_authorise_to_book_for_this_user'
      false
    else
      @condition = 'not_authorise_to_book_for_this_user'
      false
    end
  end

  def interested_project_present?
    if record.is_a?(BookingDetail) && record.project_id.present?
      user.interested_projects.approved.where(booking_portal_client_id: record.booking_portal_client_id, project_id: record.project_id).present?
    else
      true
    end
  end

  def is_assigned_lead?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      Lead.where(id: record.lead.id, closing_manager_id: user.id, booking_portal_client_id: record.booking_portal_client_id).in(customer_status: %w(engaged)).first.present?
    else
      false
    end
  end

  def is_lead_accepted?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      record.lead.accepted_by_sales?
    else
      false
    end
  end
end
