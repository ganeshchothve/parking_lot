class Admin::PublicAssetPolicy < PublicAssetPolicy
  def create?
    %w[superadmin].include?(user.role)
  end

  def update?
    create?
  end

  def destroy?
    %w[superadmin].include?(user.role)
  end
end
