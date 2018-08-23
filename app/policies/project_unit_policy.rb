class ProjectUnitPolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory? && !user.buyer?
  end

  def edit?
    valid = true
    valid = (record.status != "hold") if user.buyer?
    _role_based_check(valid)
  end

  def export?
    ['superadmin', 'admin', 'crm'].include?(user.role) && current_client.enable_actual_inventory?
  end

  def mis_report?
    export?
  end

  def update?
    edit?
  end

  def create?
    false
  end

  def hold?
    valid = record.user.kyc_ready? && current_client.enable_actual_inventory? && ((record.user.project_units.where(status: "hold").blank? && record.user_based_status(record.user) == 'available') || record.user.project_units.where(status: "hold").count == 1 && record.user.project_units.where(status: "hold").first.id == record.id)
    valid = valid && (record.user.total_unattached_balance >= current_client.blocking_amount) if user.role?('channel_partner')
    valid = (valid && user.allowed_bookings > user.booking_details.count)
    _role_based_check(valid)
  end

  def block?
    valid = ['hold'].include?(record.status) && record.user.kyc_ready? && current_client.enable_actual_inventory?
    valid = (valid && user.allowed_bookings > user.booking_details.count)
    _role_based_check(valid)
  end

  def make_available?
    valid = (record.status == 'hold' && current_client.enable_actual_inventory?)
    _role_based_check(valid)
  end

  def update_co_applicants?
    valid = (["blocked", "booked_confirmed", "booked_tentative"].include?(record.status) && current_client.enable_actual_inventory?)
    _role_based_check(valid)
  end

  def update_project_unit?
    valid = record.user.kyc_ready? && current_client.enable_actual_inventory?
    _role_based_check(valid)
  end

  def payment?
    checkout? && record.user.kyc_ready? && current_client.enable_actual_inventory?
  end

  def process_payment?
    checkout? && record.user.kyc_ready? && current_client.enable_actual_inventory?
  end

  def checkout?
    valid = record.user_id.present? && (record.user_based_status(record.user) == "booked") && record.user.kyc_ready? && current_client.enable_actual_inventory?
    _role_based_check(valid)
  end

  def permitted_attributes params={}
    attributes = ["crm", "admin", "superadmin"].include?(user.role) ? [:auto_release_on, :booking_price] : []
    attributes += (["crm", "admin", "superadmin"].include?(user.role) || make_available?) ? [:status] : []
    attributes += [:user_id] if record.user_id.blank? && record.user_based_status(user) == 'available'
    attributes += [:primary_user_kyc_id, user_kyc_ids: []] if record.user_id.present?

    if user.role?('superadmin') && ['hold', 'blocked', 'booked_tentative', 'booked_confirmed'].exclude?(record.status)
      attributes += [:name, :agreement_price, :all_inclusive_price, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :applied_discount_rate, :applied_discount_id, :base_rate, :client_id, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, :selldo_id, :erp_id, :floor_rise, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :sub_type, :type, :unit_facing_direction, costs_attributes: CostPolicy.new(user, Cost.new).permitted_attributes, data_attributes: DatumPolicy.new(user, Cost.new).permitted_attributes]
    end

    attributes.uniq
  end

  private
  def _role_based_check(valid)
    valid = (valid && (record.user_id == user.id)) if user.buyer?
    valid = (valid && (record.user.referenced_manager_ids.include?(user.id))) if user.role == "channel_partner"
    valid = (valid && true) if ['cp', 'sales', 'sales_admin', 'cp_admin', 'admin'].include?(user.role)
    valid
  end
end
