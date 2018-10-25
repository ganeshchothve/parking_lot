class SchemePolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory?(user) && (user.role?('superadmin') || user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp'))
  end

  def edit?
    create?
  end

  def new?
    current_client.enable_actual_inventory?(user) && index?
  end

  def create?
    current_client.enable_actual_inventory?(user) && ((index? && record.status == 'draft') || ['superadmin', 'admin'].include?(user.role))
  end

  def update?
    current_client.enable_actual_inventory?(user) && edit?
  end

  def approve_via_email?
    current_client.enable_actual_inventory?(user) && edit?
  end

  def permitted_attributes params={}
    attributes = [:name, can_be_applied_by: []]
    if record.new_record? || record.status == 'draft' || record.status_was == 'draft'
      attributes += [:project_id, :project_unit_id, :project_tower_id, :user_id, :user_role, :cost_sheet_template_id, :payment_schedule_template_id]
    end
    attributes += [:event] if record.approver?(user)
    if record.status == "draft"
      attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end
    attributes
  end
end
