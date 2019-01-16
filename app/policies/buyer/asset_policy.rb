class Buyer::AssetPolicy < AssetPolicy
  def create?
    "Buyer::#{record.assetable_type}Policy".constantize.new(user, record.assetable).update?
  end

  def destroy?
    "Buyer::#{record.assetable_type}Policy".constantize.new(user, record.assetable).update?
  end
end