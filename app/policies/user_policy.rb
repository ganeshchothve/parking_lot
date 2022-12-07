class UserPolicy < ApplicationPolicy
  # def index? from Application policy

  def new?
    false
  end

  def create?
    new?
  end

  def edit?
    record.id == user.id
  end

  def update?
    edit?
  end

  def update_password?
    edit? && (!user.role?('cp_owner') || user.id == record.id)
  end

  def reset_password_after_first_login?
    marketplace_client? && user.sign_in_count == 1 && !user.tenant_owner?
  end

  def resend_confirmation_instructions?
    valid = edit? && ((!record.confirmed? && record.confirmation_token.present?) || record.unconfirmed_email.present? )
    if is_client_domain?
      if record.role.in?(User::CLIENT_SCOPED_ROLES)
        valid &&= true
      else
        valid &&= false
      end
    else
      if record.role.in?(User::CLIENT_SCOPED_ROLES)
        valid &&= false
      else
        valid &&= true
      end
    end
    valid
  end

  def resend_password_instructions?
    valid = edit? && record.email.present?
    if is_client_domain?
      if record.role.in?(User::CLIENT_SCOPED_ROLES)
        valid &&= true
      else
        valid &&= false
      end
    else
      if record.role.in?(User::CLIENT_SCOPED_ROLES)
        valid &&= false
      else
        valid &&= true
      end
    end
    valid
  end

  def export?
    unless marketplace_client?
      index? && !user.role.in?(%w[sales sales_admin])
    else
      %w[superadmin admin].include?(user.role)
    end
  end

  def confirm_via_otp?
    false
  end

  def print?
    false
  end

  def asset_create?
    false
  end

  def reactivate_account?
    false
  end

  def permitted_attributes(_params = {})
    attributes = []
    if marketplace_client?
      if record.role.in?(%w(cp_owner channel_partner))
        attributes = %i[first_name last_name phone time_zone]
      end
    else
      attributes = %i[first_name last_name phone time_zone]
    end
    attributes += %i[lead_id password password_confirmation iris_confirmation temporarily_blocked]
    # Only allow admin to change email.
    attributes += [user_notification_tokens_attributes: [UserNotificationTokenPolicy.new(user, UserNotificationToken.new).permitted_attributes]]
    if marketplace_client?
      if record.role.in?(%w(cp_owner channel_partner))
        attributes += %i[email] if ((record.new_record? || user.role?('admin')))
      end
    else
      attributes += %i[email] if ((record.new_record? || user.role?('admin')))
    end
    attributes
  end
end
