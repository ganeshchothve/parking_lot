class Admin::AccountPolicy < AccountPolicy
  def index?
    if current_client.real_estate?
      %w[superadmin].include?(user.role)
    else
      false
    end
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
    attributes = %i[account_number by_default name]
  end
end
