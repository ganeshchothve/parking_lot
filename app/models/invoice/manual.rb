class Invoice::Manual < Invoice

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

end
