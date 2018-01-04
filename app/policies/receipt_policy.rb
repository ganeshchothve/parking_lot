class ReceiptPolicy < ApplicationPolicy
  def index?
    true
  end

  def new?
    if user.role?('user')
      user.kyc_ready? && (record.project_unit.blank? || booking_payment?)
    else
      record.user_id.present? && record.user.kyc_ready? && (record.project_unit.blank? || booking_payment?)
    end
  end

  def create?
    new?
  end

  def booking_payment?
    project_unit = record.project_unit
    project_unit.present? && project_unit.user_id == user.id && (project_unit.status == 'blocked' || project_unit.status == 'booked_tentative') && project_unit.pending_balance > 0 && user.kyc_ready?
  end

  def permitted_attributes params={}
    attributes = [:status, :project_unit_id, :total_amount]
    unless user.role?('user')
      attributes += [:payment_mode, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :payment_type]
    end
    attributes
  end
end
