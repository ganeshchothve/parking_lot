# Referal record is User's object.
class ReferralPolicy < Struct.new(:user, :referal)
  def index?
    user.buyer?
  end

  def create?
    index?
  end

  def new?
    index?
  end
end

class Admin::ReferralPolicy < ReferralPolicy
end

class Buyer::ReferralPolicy < ReferralPolicy
end
