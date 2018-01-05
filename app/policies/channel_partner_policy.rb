class ChannelPartnerPolicy < ApplicationPolicy
  def index?
    user.role?('admin')
  end

  def new?
    !user.present?
  end

  def edit?
    user.role?('admin')
  end

  def create?
    !user.present?
  end

  def update?
    user.role?('admin')
  end

  def permitted_attributes params={}
    attributes = [:name, :email, :phone, :rera_id, :location]
    attributes += [:status] if user.present? && user.role?('admin')
    attributes
  end
end
