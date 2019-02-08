class Admin::AccountPolicy < AccountPolicy
  def index?
    %w[superadmin].include?(user.role)
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def show?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def permitted_attributes
    attributes = %i[account_number key secret by_default name]
  end
end
