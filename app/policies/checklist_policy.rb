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
    attributes = %w[name description id]
    attributes += %w[key] if record.new_record?
    attributes
  end
end
