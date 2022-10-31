class Admin::DiscountPolicy < DiscountPolicy
  # def new? def edit? def update? from DiscountPolicy

  def index?
    user.booking_portal_client.enable_direct_payment? && %w[superadmin].include?(user.role)
  end

  def create?
    index?
  end

  def permitted_attributes(_params = {})
    attributes = [:name, :description, :start_token_number, :end_token_number, :project_id, :token_type_id]
    attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    attributes
  end

  def update_coupons?
    user.role == 'superadmin'
  end
end
