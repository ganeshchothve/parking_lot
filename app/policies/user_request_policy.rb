class UserRequestPolicy < ApplicationPolicy
  def index?
    current_client.enable_actual_inventory?
  end

  def edit?
    ((user.id == record.user_id && record.status == 'pending') || ['admin', 'crm', 'sales', 'cp', 'superadmin'].include?(user.role)) && current_client.enable_actual_inventory?
  end

  def new?
    valid = (record.user_id == user.id && user.booking_detail_ids.present? && current_client.enable_actual_inventory?)
    valid = (record.project_unit.user_based_status(user) == "booked" && record.project_unit.status != "hold") if record.project_unit_id.present?
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
    if ["resolved", "swapped"].exclude?(record.status)
      attributes = [:comments, :receipt_id, :user_id] if user.buyer?
      attributes += [:project_unit_id] if user.buyer? && record.new_record?
      attributes = [:status, :crm_comments, :reply_for_customer, :alternate_project_unit_id] if ['admin', 'crm', 'sales', 'superadmin', 'cp'].include?(user.role)
      attributes || []
    else
      []
    end
  end
end
