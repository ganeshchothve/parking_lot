class ReceiptPolicy < ApplicationPolicy
  def new?
    user.kyc_ready? && (record.project_unit.blank? || booking_payment?)
  end

  def create?
    user.kyc_ready? && (record.project_unit.blank? || booking_payment?)
  end

  def booking_payment?
    project_unit = record.project_unit
    project_unit.present? && project_unit.user_id == user.id && (project_unit.status == 'blocked' || project_unit.status == 'booked_tentative') && project_unit.pending_balance > 0 && user.kyc_ready?
  end

  def permitted_attributes params={}
    attributes = [:status, :project_unit_id, :total_amount]
    attributes
  end
end
