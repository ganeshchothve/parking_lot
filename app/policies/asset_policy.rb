class AssetPolicy < ApplicationPolicy
  def create?
    (record.assetable_type + "Policy").constantize.new(user, record.assetable).update?
  end

  def destroy?
    (record.assetable_type + "Policy").constantize.new(user, record.assetable).update?
  end

  def show?
    true
  end

  def index?
    true
  end

  def permitted_attributes params={}
    [ :file ]
  end
end
