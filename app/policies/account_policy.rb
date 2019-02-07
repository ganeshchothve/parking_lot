class AccountPolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    user.role?('superadmin')
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
