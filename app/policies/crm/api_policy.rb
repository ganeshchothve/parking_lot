class Crm::ApiPolicy < ApplicationPolicy

  def new?
    false
  end

  def create?
    new?
  end

  def permitted_attributes
    attributes = %w[resource_class path request_payload base_id request_type]
    attributes
  end
end
