class UserRequestPolicy < ApplicationPolicy
  def index?
    ['admin', 'crm', 'user'].include?(user.role)
  end

  def edit?
    (user.id == record.user_id && record.status == 'pending') || ['admin', 'crm'].include?(user.role)
  end

  def new?
    record.user_id == user.id
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:comments, :project_unit_id, :receipt_id, :user_id] if user.role?('user')
    attributes = [:status] if user.role?('admin') || user.role?('crm')
    attributes
  end
end
