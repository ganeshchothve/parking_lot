class ProjectUnitPolicy < ApplicationPolicy
  def index?
    true
  end

  def edit?
    (record.auto_release_on.present? || ["available", "not_available", "employee", "management"].include?(record.status)) && ['crm', 'admin'].include?(user.role)
  end

  def eoi?
    ['crm', 'sales', 'cp', 'admin'].include?(user.role)
  end

  def update?
    edit?
  end

  def create?
    false
  end

  def hold_project_unit?
    valid = record.user_based_status(user) == 'available' && user.buyer? && user.kyc_ready? && user.project_units.where(status: "hold").blank?
    if user.role?("employee_user")
      eids = User.where(role: "employee_user").where(confirmed_at: {"$exists": true}).pluck(:id)
      valid = valid && ProjectUnit.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).in(user_id: eids).count <= 75
    end
    valid
  end

  def update_co_applicants?
    record.user_id == user.id && ["blocked", "booked_confirmed", "booked_tentative"].include?(record.status)
  end

  def update_project_unit?
    record.user_id == user.id && user.buyer? && user.kyc_ready?
  end

  def payment?
    checkout? && user.kyc_ready?
  end

  def process_payment?
    checkout? && user.kyc_ready?
  end

  def checkout?
    (['hold', 'blocked', 'booked_tentative', 'booked_confirmed'].include?(record.status) && record.user_id == user.id) && user.kyc_ready?
  end

  def checkout_via_email?
    record.user_based_status(user) == "available" && user.kyc_ready?
  end

  def block?
    (user.project_units.count < user.allowed_bookings && !record.is_a?(ProjectUnit)) || (record.is_a?(ProjectUnit) && (['hold'].include?(record.status) && record.user_id == user.id) && user.kyc_ready?)
  end

  def permitted_attributes params={}
    attributes = [:status, :auto_release_on, :primary_user_kyc_id, user_kyc_ids: []]
    attributes
  end
end
