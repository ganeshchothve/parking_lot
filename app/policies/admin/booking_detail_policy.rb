class Admin::BookingDetailPolicy < BookingDetailPolicy

  def index?
    out = %w[admin superadmin sales sales_admin cp cp_admin gre channel_partner cp_owner].include?(user.role) && enable_actual_inventory?(user)
    out = false if user.role.in?(%w(cp_owner channel_partner)) && !interested_project_present?
    out = true if %w[account_manager account_manager_head billing_team].include?(user.role)
    out
  end

  def new?
    out = %w[admin superadmin sales sales_admin cp cp_admin gre channel_partner cp_owner].include?(user.role) && eligible_user? && enable_actual_inventory?(user) && record.project&.is_active?
    out = false if user.role.in?(%w(cp_owner channel_partner)) && !interested_project_present?
    out
  end

  def create?
    return true if is_buyer_booking_limit_exceed? && eligible_user? && enable_actual_inventory?(user)
    @condition = 'allowed_bookings'
    false
  end

  def booking?
    true
  end

  def edit?
    record.project&.is_active? && enable_actual_inventory?(user) && (!record.try(:project).try(:enable_booking_with_kyc?) || record.try(:user).try(:user_kycs).present?)
  end

  def update?
    edit?
  end

  def tasks?
    record.project&.is_active? && %w[cancelled swapped].exclude?(record.status) && (eligible_users_for_tasks? || enable_incentive_module?(user))
  end

  def mis_report?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def hold?
    record.project&.is_active? && _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed? && buyer_kyc_booking_limit_exceed?
  end

  def show_booking_link?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed? && record.try(:user).try(:buyer?) && !enable_inventory?
  end

  def show_add_booking_link?
    enable_inventory? && record.try(:user).try(:buyer?) && %w[account_manager].include?(user.role)
  end

  def enable_inventory?
    lead = record.lead
    out = true
    out = false if lead.project.is_active? && lead.project.enable_inventory
    return out
  end

  def send_under_negotiation?
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
    %w[account_manager account_manager_head].include?(user.role)
  end

  def send_booking_detail_form_notification?
    user.active_channel_partner?
  end

  def edit_booking_without_inventory?
    out = false
    out = true if record.status == 'blocked' && user.role?('account_manager_head')
    out = true if %w('booked_tentative', 'booked_confirmed') && user.role?('billing_team')
    out
  end

  def asset_create?
    %w[account_manager account_manager_head billing_team].include?(user.role)
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
    attributes += [:project_tower_name, :agreement_price, :channel_partner_id, :other_costs, :agreement_date, :project_unit_configuration, :booking_project_unit_name, :booked_on, :project_id, :primary_user_kyc_id, :project_unit_id, :user_id, :creator_id, :manager_id, :account_manager_id, :lead_id, :source, user_kyc_ids: []]
    if eligible_users_for_tasks?
      attributes += [tasks_attributes: Admin::TaskPolicy.new(user, Task.new).permitted_attributes]
    end
    attributes.uniq
  end

  private

  def eligible_users_for_tasks?
    enable_actual_inventory?(user)
    #return true if %w[admin channel_partner sales_admin sales].include?(user.role)
  end

  def need_unattached_booking_receipts_for_channel_partner
    if user.role?('channel_partner')
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
      return true if record.lead.cp_lead_activities.where(user_id: user.id).present? && user.active_channel_partner?
      @condition = 'not_authorise_to_book_for_this_user'
      false
    else
      @condition = 'not_authorise_to_book_for_this_user'
      false
    end
  end

  def interested_project_present?
    if record.is_a?(BookingDetail) && record.project_id.present?
      user.interested_projects.approved.where(project_id: record.project_id).present?
    else
      true
    end
  end
end
