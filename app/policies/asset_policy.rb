class AssetPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    true
  end

  def permitted_attributes params={}
    attributes = [:asset_type, :file, :assetable_id, :assetable_type ]

    if record.assetable_type.present? && "Admin::#{record.assetable_type}Policy".constantize.new(user, record.assetable).update?
      attributes  += [:id]
    end
    attributes
  end
end
