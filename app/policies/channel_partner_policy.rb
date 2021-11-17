class ChannelPartnerPolicy < ApplicationPolicy
  # def index? def create? def new? def update? def edit? def permitted_attributes from ApplicationPolicy

  def export?
    index?
  end

  def show?
    false
  end

  def asset_create?
    create? || user.role.in?(%w(admin cp cp_admin))
  end
end
