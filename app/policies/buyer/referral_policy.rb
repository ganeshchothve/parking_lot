class Buyer::ReferralPolicy < ReferralPolicy
  def create?
    super && record.referred_by.id == user.id
  end

  def new?
    super && user.referral_code.present?
  end
end