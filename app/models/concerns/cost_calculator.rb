module CostCalculator
  def effective_rate
    effective_rate = self.base_rate + self.floor_rise
    if scheme.payment_adjustments.present?
      scheme.payment_adjustments.in(field: ["base_rate", "floor_rise"]).each do |adj|
        effective_rate += adj.value self
      end
    end
    effective_rate
  end

  def booking_price_percent_of_agreement_price
    agreement_price > 5000000 ? 0.099 : 0.1
  end

  def pending_balance
    booking_detail.try(:pending_balance).to_f
  end

  # def pending_balance(options={})
  #   strict = options[:strict] || false
  #   user_id = options[:user_id] || self.user_id
  #   if user_id.present?
  #     receipts_total = Receipt.where(user_id: user_id, project_unit_id: self.id)
  #     if strict
  #       receipts_total = receipts_total.where(status: "success")
  #     else
  #       receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
  #     end
  #     receipts_total = receipts_total.sum(:total_amount)
  #     return (self.booking_price - receipts_total)
  #   else
  #     return self.booking_price
  #   end
  # end

  # def total_amount_paid
  #   receipts.where(user_id: self.user_id).where(status: 'success').sum(:total_amount)
  # end

  # def total_tentative_amount_paid
  #   receipts.where(user_id: self.user_id).in(status: ['success', 'clearance_pending']).sum(:total_amount)
  # end

  def calculate_agreement_price
    (base_price + total_agreement_costs + scheme.payment_adjustments.where(field: "agreement_price").collect{|adj| adj.value(self)}.sum).round
  end

  def calculate_all_inclusive_price
    (calculate_agreement_price + total_outside_agreement_costs + scheme.payment_adjustments.where(field: "all_inclusive_price").collect{|adj| adj.value(self)}.sum).round
  end

  def base_price
    saleable * effective_rate
  end

  def total_outside_agreement_costs
    costs.where(category: 'outside_agreement').collect do |cost|
      cost.value
    end.sum
  end

  def total_agreement_costs
    costs.where(category: 'agreement').collect do |cost|
      cost.value
    end.sum
  end
end
