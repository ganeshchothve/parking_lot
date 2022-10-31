# Referal record is User's object.
class ReferralPolicy < ApplicationPolicy

  def index?
    user.booking_portal_client.enable_referral_bonus && user.role.in?(%w(cp_owner channel_partner))
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
