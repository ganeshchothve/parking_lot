class UserPolicy < ApplicationPolicy
  def index?
    ['channel_partner', 'admin', 'crm', 'sales', 'cp'].include?(user.role)
  end

  def resend_confirmation_instructions?
    index?
  end

  def resend_password_instructions?
    index?
  end

  def export?
    ['admin', 'crm'].include?(user.role)
  end

  def export_customer_book?
    ['admin', 'crm'].include?(user.role)
  end
  
  def export_cp_report?
    ['admin', 'cp'].include?(user.role)
  end

  def edit?
    record.id == user.id || ['crm', 'admin'].include?(user.role)
  end

  def new?
    user.role?('admin') || ((user.role?('channel_partner') && record.role?("user")) || (user.role?('crm') && record.buyer?))
  end

  def create?
    new?
  end

  def update?
    user.role?('admin') || (user.role?('channel_partner') && record.channel_partner_id == user.id) || (record.id == user.id)
  end

  def permitted_attributes params={}
    attributes = [:first_name, :last_name, :email, :phone, :lead_id, :password, :password_confirmation]
    attributes += [:channel_partner_id] if user.role?('channel_partner')
    attributes += [:role, :channel_partner_id, :rera_id, :location, :allowed_bookings] if user.role?('admin')
    attributes
  end
end
