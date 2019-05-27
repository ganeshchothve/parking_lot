module PriceCalculator

  def calculated_costs
    out = {}
    costs.each { |c| out[c.key] = c.value }
    out.with_indifferent_access
  end

  def calculated_cost(name)
    costs.where(name: name).first.value
  rescue StandardError
    0
  end

  def calculated_data
    out = {}
    data.each { |c| out[c.key] = c.value }
    out.with_indifferent_access
  end
  
  def effective_rate
    effective_rate = self.base_rate + self.floor_rise
    if booking_detail_scheme.payment_adjustments.present?
      booking_detail_scheme.payment_adjustments.in(field: ["base_rate", "floor_rise"]).each do |adj|
        effective_rate += adj.value self
      end
    end
    effective_rate
  end

  def booking_price_percent_of_agreement_price
    agreement_price > 5000000 ? 0.099 : 0.1
  end

  def pending_balance(options={})
    strict = options[:strict] || false
    user_id = options[:user_id] || self.user_id
    if user_id.present?
      receipts_total = Receipt.where(user_id: user_id, booking_detail_id: self.id)
      if strict
        receipts_total = receipts_total.where(status: "success")
      else
        receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
      end
      receipts_total = receipts_total.sum(:total_amount)
      return (self.project_unit.booking_price - receipts_total)
    else
      return self.project_unit.booking_price
    end
  end

  def total_tentative_amount_paid
    receipts.where(user_id: self.user_id).in(status: ['success', 'clearance_pending']).sum(:total_amount)
  end

  def total_amount_paid
    receipts.success.sum(:total_amount)
  end

  def total_agreement_costs
    costs.where(category: 'agreement').collect do |cost|
      cost.value
    end.sum
  end

  def calculate_agreement_price
    (base_price + total_agreement_costs + booking_detail_scheme.payment_adjustments.where(field: "agreement_price").collect{|adj| adj.value(self)}.sum).round
  end

  def calculate_all_inclusive_price
    (calculate_agreement_price + total_outside_agreement_costs + booking_detail_scheme.payment_adjustments.where(field: "all_inclusive_price").collect{|adj| adj.value(self)}.sum).round
  end

  def base_price
    saleable * effective_rate
  end

  def total_outside_agreement_costs
    costs.where(category: 'outside_agreement').collect do |cost|
      cost.value
    end.sum
  end

end
