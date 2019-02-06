class AccountPolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    current_client.enable_actual_inventory?(user)
  end

  def update?
    false
  end

  def edit?
    false
  end

  def create?
    new?
  end

  def export?
    false
  end
end
