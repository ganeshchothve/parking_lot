class PublicAssetPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    valid = user.active_channel_partner?
    if record.is_a?(PublicAsset) && user.role == 'channel_partner'
      cp = user.channel_partner
      valid ||= (record.public_assetable_id == cp.id && record.public_assetable_type == cp.class.model_name.name.to_s) if cp
    end
    valid
  end

  def permitted_attributes params={}
    attributes = [:asset_type, :file, :public_assetable_id, :public_assetable_type, :document_type ]
    if record.public_assetable_type.present? && "Admin::#{record.public_assetable_type}Policy".constantize.new(user, record.public_assetable).update?
      attributes  += [:id]
    end
    attributes
  end
end
