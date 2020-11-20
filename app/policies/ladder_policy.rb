class LadderPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    if record.incentive_scheme && record.incentive_scheme.draft?
      attributes += [:id, :stage, :start_value, :end_value, :inclusive, :_destroy, payment_adjustment_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end
    attributes.uniq
  end
end
