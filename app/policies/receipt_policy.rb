class ReceiptPolicy < ApplicationPolicy
  def new?
    booking_payment?
  end

  def create?
    booking_payment?
  end

  def booking_payment?
    project_unit = record.project_unit
    project_unit.present? && project_unit.user_id == user.id && (project_unit.status == 'blocked' || project_unit.status == 'booked_tentative') && project_unit.total_balance_pending > 0
  end

  def permitted_attributes params={}
    attributes = [:status, :project_unit_id, :total_amount]
    attributes
  end
end
