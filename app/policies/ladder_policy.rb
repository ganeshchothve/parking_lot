class LadderPolicy < ApplicationPolicy
  def permitted_attributes
    [:id, :stage, :start_value, :end_value, :inclusive, :_destroy, payment_adjustment_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
  end
end
