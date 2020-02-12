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

  def permitted_attributes
    attributes = %w[name domain]
    attributes
  end
end
