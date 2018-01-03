class ProjectUnitPolicy < ApplicationPolicy
  def create?
    false
  end

  def hold_project_unit?
    record.status == 'available'
  end

  def update_project_unit?
    record.user_id == user.id
  end

  def payment?
    checkout?
  end

  def process_payment?
    checkout?
  end

  def checkout?
    (['hold', 'blocked', 'booked_tentative', 'booked_confirmed'].include?(record.status) && record.user_id == user.id)
  end

  def block?
    (['hold'].include?(record.status) && record.user_id == user.id)
  end

  def permitted_attributes params={}
    attributes = [:status, :user_id]
    attributes
  end
end
