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
    edit?
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

  def confirm_via_otp?
    false
  end

  def print?
    false
  end

  def permitted_attributes(_params = {})
    attributes = %i[first_name last_name email phone lead_id password password_confirmation time_zone]
    attributes
  end
end
