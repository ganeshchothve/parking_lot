class Crm::BasePolicy < ApplicationPolicy

  def index?
    false
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def choose_crm?
    index?
  end

  def permitted_attributes
    attributes = %w[name domain request_payload request_headers]
    attributes
  end
end
