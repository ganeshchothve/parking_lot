class Buyer::PublicAssetPolicy < PublicAssetPolicy
  def index?
    %w[superadmin].include?(user.role)
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
