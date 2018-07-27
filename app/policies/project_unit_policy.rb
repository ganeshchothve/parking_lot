class ProjectUnitPolicy < ApplicationPolicy
  def index?
    true
  end

  def edit?
    ((['blocked', 'booked_tentative', 'booked_confirmed', 'error'].include?(record.status) && record.auto_release_on.present?) || ["available", "not_available", "employee", "management"].include?(record.status))
  end

  def export?
    ['superadmin', 'admin', 'crm'].include?(user.role)
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
    record.user_based_status(record.user) == 'available' && record.user.kyc_ready? && record.user.project_units.where(status: "hold").blank?
  end

  def make_available?
    valid = (record.status == 'hold')
    _role_based_check(valid)
  end

  def update_co_applicants?
    valid = (["blocked", "booked_confirmed", "booked_tentative"].include?(record.status))
    _role_based_check(valid)
  end

  def update_project_unit?
    valid = record.user.kyc_ready?
    _role_based_check(valid)
  end

  def payment?
    checkout? && record.user.kyc_ready?
  end

  def process_payment?
    checkout? && record.user.kyc_ready?
  end

  def checkout?
    valid = (record.user_based_status(record.user) == "booked") && record.user.kyc_ready?
    _role_based_check(valid)
  end

  def checkout_via_email?
    valid = record.user_based_status(user) == "available" && user.kyc_ready?
    _role_based_check(valid)
  end

  def block?
    valid = (record.user.project_units.count < record.user.allowed_bookings && !record.is_a?(ProjectUnit)) || (record.is_a?(ProjectUnit) && ['hold'].include?(record.status) && user.kyc_ready?)
    _role_based_check(valid)
  end

  def permitted_attributes params={}
    attributes = ["crm","admin"].include?(user.role) ? [:auto_release_on] : []
    attributes += (["crm","admin"].include?(user.role) || make_available?) ? [:status] : []
    attributes += [:user_id] if record.user_id.blank?
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
