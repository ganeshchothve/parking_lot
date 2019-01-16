class Admin::SchemePolicy < SchemePolicy
  # def new? def edit? def update? def approve_via_email? from SchemePolicy

  def index?
    current_client.enable_actual_inventory?(user) && %w[superadmin admin sales crm cp].include?(user.role)
  end

  def create?
    current_client.enable_actual_inventory?(user) && ((index? && record.status == 'draft') || %w[superadmin admin].include?(user.role))
  end

  def payment_adjustments_for_unit?
    true
  end

  def permitted_attributes(_params = {})
    attributes = [:name, can_be_applied_by: []]
    if record.new_record? || record.status == 'draft' || record.status_was == 'draft'
      attributes += %i[project_id project_unit_id project_tower_id user_id user_role cost_sheet_template_id payment_schedule_template_id]
    end
    attributes += [:event] if record.approver?(user)
    if record.status == 'draft'
      attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end
    attributes
  end
end