class Admin::PaymentTypePolicy < PaymentTypePolicy
  def index?
    %w[superadmin].include?(user.role)
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def show?
    %w[superadmin].include?(user.role)
  end

  def new?
    index?
  end

end
