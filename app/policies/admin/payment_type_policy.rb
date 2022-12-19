class Admin::PaymentTypePolicy < PaymentTypePolicy
  def index?
    if current_client.real_estate?
      %w[superadmin].include?(user.role)
    else
      false
    end
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
