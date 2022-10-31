class Buyer::PaymentTypePolicy < PaymentTypePolicy
  def index?
    false
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def show?
    index?
  end

end
