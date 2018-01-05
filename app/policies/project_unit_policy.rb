class ProjectUnitPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    false
  end

  def hold_project_unit?
    record.status == 'available' && user.role?('user') && user.kyc_ready?
  end

  def update_project_unit?
    record.user_id == user.id && user.role?('user') && user.kyc_ready?
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

  def block?
    (['hold'].include?(record.status) && record.user_id == user.id) && user.kyc_ready?
  end

  def permitted_attributes params={}
    attributes = []
    if params[:status].present? && params[:status] == 'hold'
      attributes += [:status]
    end
    attributes += [user_kyc_ids: []]
    attributes
  end
end
