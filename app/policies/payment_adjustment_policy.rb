class PaymentAdjustmentPolicy < SchemePolicy
  def permitted_attributes params={}
    [:id, :name, :field, :absolute_value, :absolute_value_type, :formula, :_destroy]
  end
end
