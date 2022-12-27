class PhasePolicy < ApplicationPolicy

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
