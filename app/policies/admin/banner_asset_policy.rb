class Admin::BannerAssetPolicy < ApplicationPolicy
  def index?
    %w[superadmin].include?(user.role)
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