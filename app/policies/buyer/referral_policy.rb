class Buyer::ReferralPolicy < ReferralPolicy
  def create?
    super && record.referred_by.id == user.id
  end
end