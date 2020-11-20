class LadderPolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :stage, :start_value, :end_value, :inclusive, payment_adjustment_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    attributes += [:_destroy] if record.id.present?
    attributes.uniq
  end
end
