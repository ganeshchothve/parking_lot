class ChecklistPolicy < ApplicationPolicy

  def index?
    user.role?('superadmin')
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def destroy?
    index?
  end

  def permitted_attributes
    attributes = %w[name description id order]
    attributes += %w[key tracked_by] if record.new_record?
    attributes
  end
end
