class ProjectUnitPolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory?
  end

  def edit?
    _role_based_check(true)
  end

  def export?
    ['superadmin', 'admin'].include?(user.role) && current_client.enable_actual_inventory?
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
    valid = record.user_based_status(record.user) == 'available' && record.user.kyc_ready? && record.user.project_units.where(status: "hold").blank? && current_client.enable_actual_inventory?
    valid = valid && (record.user.total_unattached_balance >= current_client.blocking_amount) if user.role?('channel_partner')
    _role_based_check(valid)
  end

  def block?
    valid = ['hold'].include?(record.status) && record.user.kyc_ready? && current_client.enable_actual_inventory?
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
    valid = (record.user_based_status(record.user) == "booked") && record.user.kyc_ready? && current_client.enable_actual_inventory?
    _role_based_check(valid)
  end

  def permitted_attributes params={}
    attributes = ["crm","admin"].include?(user.role) ? [:auto_release_on] : []
    attributes += (["crm","admin"].include?(user.role) || make_available?) ? [:status] : []
    attributes += [:user_id] if record.user_id.blank? && record.user_based_status(user) == 'available'
    attributes += [:primary_user_kyc_id, user_kyc_ids: []]
    attributes
  end

  private
  def _role_based_check(valid)
    valid = (valid && (record.user_id == user.id)) if user.buyer?
    valid = (valid && (record.user.referenced_channel_partner_ids.include?(user.id))) if user.role == "channel_partner"
    valid = (valid && true) if ['cp', 'sales', 'admin'].include?(user.role)
    valid
  end
end
