class Buyer::AssetPolicy < AssetPolicy
  def index?
    false
  end

  def create?
    "Buyer::#{record.assetable_type}Policy".constantize.new(user, record.assetable).asset_create?
  end

  def update?
    record.assetable.try(:user_id) == user.id || record.assetable.try(:id) == user.id
  end

  def destroy?
    "Buyer::#{record.assetable_type}Policy".constantize.new(user, record.assetable).asset_update?
  end
end
