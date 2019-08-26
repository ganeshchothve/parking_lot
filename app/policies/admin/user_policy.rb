class Admin::UserPolicy < UserPolicy
  # def resend_confirmation_instructions? def resend_password_instructions? def export? def update_password? def update? def create? from UserPolicy

  def index?
    !user.buyer?
  end

  def new?
    if current_client.roles_taking_registrations.include?(user.role)
      if user.role?('superadmin')
        true
      elsif user.role?('admin')
        !record.role?('superadmin')
      elsif user.role?('channel_partner')
        record.role?('user')
      elsif user.role?('sales_admin')
        record.buyer? || record.role?('sales')
      elsif user.role?('cp_admin')
        record.buyer? || %w[channel_partner cp].include?(record.role)
      elsif user.role?('cp')
        record.buyer? || record.role?('channel_partner')
      elsif !user.buyer?
        record.buyer?
      end
    else
      false
    end
  end

  def edit?
    super || new?
  end

  def confirm_user?
    if %w[admin superadmin].include?(user.role) && !record.confirmed?
      true
    else
      @condition = 'cannot_confirm_user'
      false
    end
  end

  def confirm_via_otp?
    !record.confirmed? && record.phone.present? && new? && !user.buyer?
  end

  def print?
    record.buyer?
  end

  def portal_stage_chart?
    true
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:is_active] if record.persisted? && record.id != user.id
    if %w[admin superadmin cp_admin].include?(user.role) && record.role?('channel_partner')
      attributes += [:manager_id]
      attributes += [:manager_change_reason] if record.persisted?
    end
    if %w[admin superadmin cp_admin sales_admin].include?(user.role) && record.buyer?
      attributes += [:manager_id]
      attributes += [:manager_change_reason] if record.persisted?
      attributes += [:allowed_bookings] if current_client.allow_multiple_bookings_per_user_kyc?
    end
    attributes += [:login_otp] if confirm_via_otp?
    attributes += [:rera_id] if record.role?('channel_partner')
    attributes += [:premium] if record.role?('channel_partner') && user.role?('admin')
    attributes += [:role] if %w[superadmin admin].include?(user.role)
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end
end
