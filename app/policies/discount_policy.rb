class DiscountPolicy < ApplicationPolicy
  def index?
    user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp')
  end

  def edit?
    (index? && record.status == 'draft') || ['admin'].include?(user.role)
  end

  def new?
    index?
  end

  def create?
    (index? && record.status == 'draft') || ['admin'].include?(user.role)
  end

  def update?
    edit?
  end

  def approve_via_email?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:name]
    if record.new_record? || record.status == 'draft' || record.status_was == 'draft'
      attributes += [:project_id, :project_unit_id, :project_tower_id, :user_id, :user_role, :value]
    end
    attributes += [:status] if user.role?('admin')
    attributes
  end
end
