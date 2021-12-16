class Admin::PublicAssetPolicy < PublicAssetPolicy
  def create?
    "Admin::#{record.public_assetable_type}Policy".constantize.new(user, record.public_assetable).asset_create?
  end

  def update?
    create?
  end

  def destroy?
    "Admin::#{record.public_assetable_type}Policy".constantize.new(user, record.public_assetable)
  end
end
