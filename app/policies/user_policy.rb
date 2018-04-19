class UserPolicy < ApplicationPolicy
  def index?
    ['channel_partner', 'admin', 'crm', 'sales'].include?(user.role)
  end

  def resend_confirmation_instructions?
    index?
  end

  def export?
    ['admin', 'crm', 'sales'].include?(user.role)
  end

  def edit?
    record.id == user.id || ['crm', 'sales', 'admin'].include?(user.role)
  end

  def new?
    user.role?('admin') || (user.role?('channel_partner') && record.buyer?)
  end

  def create?
    user.role?('admin') || (user.role?('channel_partner') && record.buyer?)
  end

  def update?
    user.role?('admin') || (user.role?('channel_partner') && record.channel_partner_id == user.id) || (record.id == user.id)
  end

  def permitted_attributes params={}
    attributes = [:first_name, :last_name, :email, :phone, :lead_id, :password, :password_confirmation]
    attributes += [:channel_partner_id] if user.role?('channel_partner')
    attributes += [:role, :channel_partner_id, :rera_id, :location] if user.role?('admin')
    attributes
  end
end
