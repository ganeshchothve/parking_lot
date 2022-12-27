class Admin::DiscountPolicy < DiscountPolicy
  # def new? def edit? def update? from DiscountPolicy

  def index?
    if current_client.real_estate?
      user.booking_portal_client.payment_enabled? && %w[superadmin].include?(user.role)
    else
      false
    end
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
