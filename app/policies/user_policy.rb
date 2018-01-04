class UserPolicy < ApplicationPolicy
  def index?
    ['channel_partner', 'admin'].include?(user.role)
  end

  def edit?
    record.user_id == user.id
  end

  def new?
    user.role?('admin') || (user.role?('channel_partner') && record.role?('user'))
  end

  def create?
    user.role?('admin') || (user.role?('channel_partner') && record.role?('user'))
  end

  def update?
    user.role?('admin') || (user.role?('channel_partner') && record.channel_partner_id == user.id) || (record.user_id == user.id)
  end

  def permitted_attributes params={}
    attributes = [:name, :email, :phone, :lead_id]
    attributes += [:channel_partner_id] if user.role?('channel_partner')
    attributes += [:role, :channel_partner_id] if user.role?('admin')
    attributes
  end
end
