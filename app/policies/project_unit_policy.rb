class ProjectUnitPolicy < ApplicationPolicy
  # def new? def index? def permitted_attributes from ApplicationPolicy

  def ds?
    false
  end

  def show?
    index?
  end

  def edit?
    false
  end

  def print?
    show?
  end

  def export?
    false
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

  def send_cost_sheet_and_payment_schedule?
    false
  end

  def make_available?
    valid = (record.status == 'hold' && record.booking_portal_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_scheme?
    false
  end

  def update_co_applicants?
    valid = (ProjectUnit.booking_stages.include?(record.status) && record.booking_portal_client.enable_actual_inventory?(user))
    _role_based_check(valid)
  end

  def update_project_unit?
    valid = record.user.confirmed? && record.user.kyc_ready? && record.booking_portal_client.enable_actual_inventory?(user)
    _role_based_check(valid)
  end

  def payment?
    checkout? && record.user.confirmed? && record.user.kyc_ready? && record.booking_portal_client.enable_actual_inventory?(user)
  end

  def process_payment?
    checkout? && record.user.confirmed? && record.user.kyc_ready? && record.booking_portal_client.enable_actual_inventory?(user)
  end

  def send_under_negotiation?
    checkout?
  end

  def _role_based_check(valid)
    false
  end

  def quotation?
    record.available?
  end
end
