class UserRequestPolicy < ApplicationPolicy
  def index?
    true
  end

  def edit?
    (user.id == record.user_id && record.status == 'pending') || ['admin', 'crm', 'sales', 'cp'].include?(user.role)
  end

  def new?
    record.user_id == user.id && user.booking_detail_ids.present?
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
    if ["resolved", "swapped"].exclude?(record.status)
      attributes = [:comments, :receipt_id, :user_id] if user.buyer?
      attributes += [:project_unit_id] if user.buyer? && record.new_record?
      attributes = [:status, :crm_comments, :reply_for_customer, :alternate_project_unit_id] if user.role?('admin') || user.role?('crm') || user.role?('sales') || user.role?('cp')
      attributes
    else
      []
    end
  end
end
