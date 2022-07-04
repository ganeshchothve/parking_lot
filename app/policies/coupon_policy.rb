class CouponPolicy < ApplicationPolicy

  def show?
    !record.receipt.status.in?(%w(failed available_for_refund refunded cancelled))
  end
  
end
