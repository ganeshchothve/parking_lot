class AssetPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    valid = user.active_channel_partner?
    if record.is_a?(Asset) && user.role == 'channel_partner'
      cp = user.associated_channel_partner
      valid ||= (record.assetable_id == cp.id && record.assetable_type == cp.class.model_name.name.to_s)
    end
    valid
  end

  def permitted_attributes params={}
    attributes = [:asset_type, :file, :assetable_id, :assetable_type, :document_type ]

    if record.assetable_type.present? && "Admin::#{record.assetable_type}Policy".constantize.new(user, record.assetable).update?
      attributes  += [:id]
    end
    attributes
  end
end
