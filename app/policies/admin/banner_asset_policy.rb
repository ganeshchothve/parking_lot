class Admin::BannerAssetPolicy < ApplicationPolicy
  def index?
    if current_client.real_estate?
      %w[superadmin].include?(user.role)
    else
      false
    end
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    index?
  end

  def update?
    edit?
  end

  def destroy?
    index?
  end

  def permitted_attributes
    attributes = [:banner_image, :mobile_banner_image, :url, :publish]
  end
end
