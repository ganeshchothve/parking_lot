class DiscountPolicy < ApplicationPolicy
  # def index? def create? def permitted_attributes from ApplicationPolicy

  def new?
    index?
  end

  def edit?
    create?
  end

  def update?
    edit?
  end

  def destroy?
    create?
  end

  def update_coupons?
    false
  end
end
