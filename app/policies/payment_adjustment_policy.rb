class PaymentAdjustmentPolicy < SchemePolicy
  def permitted_attributes params={}
    [:id, :name, :field, :absolute_value, :formula, :_destroy]
  end
end
