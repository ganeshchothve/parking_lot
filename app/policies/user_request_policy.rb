class UserRequestPolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory?
  end

  def edit?
    ((user.id == record.user_id && record.status == 'pending') || ['admin', 'crm', 'sales', 'cp', 'superadmin'].include?(user.role)) && current_client.enable_actual_inventory?
  end

  def new?
    valid = true
    if record.project_unit_id.present?
      valid = valid && (record.project_unit.user_based_status(user) == "booked" && record.project_unit.status != "hold")
    end
    valid = valid && UserRequest.where(request_type: record.request_type).where(user_id: record.user.id).where(project_unit_id: record.project_unit_id).where(status: "pending").blank? if record.project_unit_id.present?
    valid = valid && (user.buyer? ? (record.user_id == user.id) : ['superadmin', 'admin', 'crm'].include?(user.role))
    valid
  end

  def export?
    ['admin'].include?(user.role) && current_client.enable_actual_inventory?
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = []
    if ["resolved", "swapped"].exclude?(record.status)
      attributes += [:comments, :receipt_id, :user_id] if user.buyer?
      attributes += [:project_unit_id] if record.new_record?
      if ['admin', 'crm', 'sales', 'superadmin', 'cp'].include?(user.role)
        attributes += [:crm_comments, :reply_for_customer, :alternate_project_unit_id]
        attributes += [:status] if record.persisted?
      end
    end
    attributes
  end
end
