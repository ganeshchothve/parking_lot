class SchemePolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory? && current_client.enable_discounts? && (user.role?('superadmin') || user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp'))
  end

  def edit?
    create?
  end

  def new?
    current_client.enable_actual_inventory? && current_client.enable_discounts? && index?
  end

  def create?
    current_client.enable_actual_inventory? && current_client.enable_discounts? && ((index? && record.status == 'draft') || ['superadmin', 'admin'].include?(user.role))
  end

  def update?
    current_client.enable_actual_inventory? && current_client.enable_discounts? && edit?
  end

  def approve_via_email?
    current_client.enable_actual_inventory? && current_client.enable_discounts? && edit?
  end

  def permitted_attributes params={}
    attributes = [:name]
    if record.new_record? || record.status == 'draft' || record.status_was == 'draft'
      attributes += [:project_id, :project_unit_id, :project_tower_id, :user_id, :user_role, :value]
    end
    attributes += [:status] if user.role?('admin') || user.role?('superadmin')
    attributes
  end
end
