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
    marketplace_portal? && user.sign_in_count == 1 && !user.tenant_owner?
  end

  def resend_confirmation_instructions?
    edit?
  end

  def resend_password_instructions?
    edit?
  end

  def export?
    index?
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
    if marketplace_portal?
      if record.role.in?(%w(cp_owner channel_partner))
        attributes = %i[first_name last_name phone time_zone]
      end
    else
      attributes = %i[first_name last_name phone time_zone]
    end
    attributes += %i[lead_id password password_confirmation iris_confirmation temporarily_blocked]
    # Only allow admin to change email.
    attributes += [user_notification_tokens_attributes: [UserNotificationTokenPolicy.new(user, UserNotificationToken.new).permitted_attributes]]
    attributes += %i[email] if ((record.new_record? || user.role?('admin')) && !marketplace_portal?)
    attributes
  end
end
