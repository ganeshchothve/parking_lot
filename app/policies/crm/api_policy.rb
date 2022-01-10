class Crm::ApiPolicy < ApplicationPolicy

  def new?
    false
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end

  def show_response?
    new?
  end

  def permitted_attributes
    attributes = %w[resource_class path request_payload base_id _type is_active event]
    attributes
  end
end
