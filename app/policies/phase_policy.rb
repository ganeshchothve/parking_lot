class PhasePolicy < ApplicationPolicy

  def index?
    user.role?('superadmin')
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
    index
  end

  def permitted_attributes(_params = {})
    %i[name account_id project_id]
  end

end
