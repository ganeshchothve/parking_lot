class UserRequestPolicy < ApplicationPolicy
  def index?
    true
  end

  def edit?
    (user.id == record.user_id && record.status == 'pending') || ['admin', 'crm', 'sales', 'cp'].include?(user.role)
  end

  def new?
    record.user_id == user.id
  end
  
  def export?
    ['admin', 'crm'].include?(user.role)
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:comments, :receipt_id, :user_id] if user.buyer?
    attributes += [:project_unit_id] if user.buyer? && record.new_record?
    attributes = [:status] if user.role?('admin') || user.role?('crm') || user.role?('sales') || user.role?('cp')
    attributes
  end
end
