class ChecklistPolicy < ApplicationPolicy

  def index?
    if current_client.real_estate?
      user.role?('superadmin')
    else
      false
    end
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
