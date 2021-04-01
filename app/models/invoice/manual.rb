class Invoice::Manual < Invoice
  include NumberIncrementor

  field :number, type: String
  field :gst_amount, type: Float, default: 0.0

  scope :filter_by_number, ->(number) { where(number: number) }

  validates :gst_amount, numericality: { greater_than_or_equal_to: 0 }

  def amount_before_adjustment
    _amount = amount + gst_amount.to_f
    _amount -= incentive_deduction.amount if incentive_deduction.try(:approved?)
    _amount
  end

  def amount_before_gst
    _amount = amount + payment_adjustment.try(:absolute_value).to_f
    _amount -= incentive_deduction.amount if incentive_deduction.try(:approved?)
    _amount
  end

  def amount_before_deduction
    amount + gst_amount.to_f + payment_adjustment.try(:absolute_value).to_f
  end

  def calculate_net_amount
    _amount = amount + gst_amount.to_f + payment_adjustment.try(:absolute_value).to_f
    _amount -= incentive_deduction.amount if incentive_deduction.try(:approved?)
    _amount
  end
end