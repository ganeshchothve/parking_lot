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
    attributes = %w[resource_class path request_payload base_id request_type response_decryption_key response_data_location]
    attributes
  end
end
