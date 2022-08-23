class Buyer::CouponPolicy < CouponPolicy

  def show?
    super && user.role.in?(User::BUYER_ROLES)
  end

end
