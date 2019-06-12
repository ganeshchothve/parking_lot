class Admin::AssetPolicy < AssetPolicy
  def create?
    "Admin::#{record.assetable_type}Policy".constantize.new(user, record.assetable).asset_create?
  end

  def update?
    create?
  end

  def destroy?
    "Admin::#{record.assetable_type}Policy".constantize.new(user, record.assetable).update?
  end
end