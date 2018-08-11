class UserPolicy < ApplicationPolicy
  def index?
    ['superadmin', 'channel_partner', 'admin', 'crm', 'sales', 'cp'].include?(user.role)
  end

  def resend_confirmation_instructions?
    index?
  end

  def resend_password_instructions?
    index?
  end

  def export?
    ['superadmin', 'admin'].include?(user.role)
  end

  def edit?
    record.id == user.id || ['superadmin', 'crm', 'admin'].include?(user.role)
  end

  def update_password?
    edit?
  end

  def new?
    if user.role?('superadmin') || user.role?('admin')
      return true
    elsif user.role?('channel_partner')
      return record.role?("user")
    else
      return record.buyer?
    end
  end

  def create?
    new?
  end

  def update?
    user.role?('superadmin') || user.role?('admin') || (user.role?('channel_partner') && record.channel_partner_id == user.id) || (record.id == user.id)
  end

  def permitted_attributes params={}
    attributes = [:first_name, :last_name, :email, :phone, :lead_id, :password, :password_confirmation, :time_zone]
    attributes += [:channel_partner_id] if user.role?('channel_partner') && record.new_record? && record.buyer?
    attributes += [:channel_partner_id, :allowed_bookings] if user.role?('admin') || user.role?("superadmin") && record.buyer?
    attributes += [:channel_partner_change_reason] if user.role?('admin') || user.role?("superadmin")
    attributes += [:rera_id] if record.role?("channel_partner")
    attributes += [:role] if user.role?('superadmin') || user.role?("admin")
    attributes
  end
end
