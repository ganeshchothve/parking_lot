class UserPolicy < ApplicationPolicy
  def index?
    !user.buyer?
  end

  def resend_confirmation_instructions?
    index?
  end

  def resend_password_instructions?
    index?
  end

  def export?
    index?
  end

  def edit?
    record.id == user.id || new?
  end

  def update_password?
    edit?
  end

  def new?
    if user.role?('superadmin')
      true
    elsif user.role?('admin')
      !record.role?("superadmin")
    elsif user.role?('channel_partner')
      record.role?("user")
    elsif user.role?('cp') || user.role?('cp_admin')
      record.buyer? || record.role?('channel_partner')
    elsif !user.buyer?
      record.buyer?
    end
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:first_name, :last_name, :email, :phone, :lead_id, :password, :password_confirmation, :time_zone]
    attributes += [:is_active] if record.persisted? && record.id != user.id
    attributes += [:manager_id] if user.role?('channel_partner') && record.new_record? && record.buyer?
    attributes += [:manager_id, :allowed_bookings] if (user.role?('admin') || user.role?("superadmin")) && (record.buyer? || record.role?("channel_partner"))
    attributes += [:manager_change_reason] if (user.role?('admin') || user.role?("superadmin")) && record.persisted?
    attributes += [:rera_id] if record.role?("channel_partner")
    attributes += [:role] if user.role?('superadmin') || user.role?("admin")
    attributes
  end
end
