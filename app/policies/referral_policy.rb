# Referal record is User's object.
class ReferralPolicy < ApplicationPolicy

  def index?
    if current_client.real_estate?
      user.role.in?(%w(cp_owner channel_partner))
    else
      false
    end
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def generate_code?
    index?
  end

  def permitted_attributes(_params = {})
    %i[first_name last_name email phone]
  end
end
