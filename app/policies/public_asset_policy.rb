class PublicAssetPolicy < ApplicationPolicy

  def show?
    true
  end

  def index?
    %w[superadmin].include?(user.role)
  end

  def permitted_attributes params={}
    attributes = [:asset_type, :file, :public_assetable_id, :public_assetable_type, :document_type ]
    if record.public_assetable_type.present? && %w[superadmin].include?(user.role)
      attributes  += [:id]
    end
    attributes
  end
end
