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
    if booking_detail_scheme
      booking_detail_scheme.payment_adjustments.in(field: ["base_rate", "floor_rise"]).each do |adj|
        effective_rate += adj.value self
      end
    end
    effective_rate
  end

  def booking_price_percent_of_agreement_price
    agreement_price > 5000000 ? 0.099 : 0.1
  end

  def total_agreement_costs
    costs.where(category: 'agreement').collect do |cost|
      cost.value
    end.sum
  end

  def calculate_agreement_price
    agreement_price = base_price + total_agreement_costs
    if booking_detail_scheme
      agreement_price += (booking_detail_scheme.payment_adjustments.where(field: "agreement_price").collect{|adj| adj.value(self)}.sum).round
    end
    agreement_price
  end

  def calculate_all_inclusive_price
    all_incl_price = calculate_agreement_price + total_outside_agreement_costs
    if booking_detail_scheme
      all_incl_price += (booking_detail_scheme.payment_adjustments.where(field: "all_inclusive_price").collect{|adj| adj.value(self)}.sum).round
    end
    return all_incl_price if self.is_a? ProjectUnit
    all_incl_price += token_discount if token_discount.present?
    all_incl_price
  end

  def base_price
    saleable * effective_rate
  end

  def total_outside_agreement_costs
    costs.where(category: 'outside_agreement').collect do |cost|
      cost.value
    end.sum
  end

  def payment_against_agreement
    receipts.where({'$and' => [ { payment_type: 'agreement'}, { '$or' => [{ '$and' => [{payment_mode: 'online'}, {status: 'success'} ] }, { '$and' => [{payment_mode: {'$nin': ['online'] } }, {status: { '$in': [ 'pending', 'clearance_pending', 'success' ] } } ] } ] } ] } ).sum(:total_amount)
  end

  def payment_against_stamp_duty
    receipts.where({'$and' => [ { payment_type: 'stamp_duty'}, { '$or' => [{ '$and' => [{payment_mode: 'online'}, {status: 'success'} ] }, { '$and' => [{payment_mode: {'$nin': ['online'] } }, {status: { '$in': [ 'pending', 'clearance_pending', 'success' ] } } ] } ] } ] } ).sum(:total_amount)
  end

  def calculate_agreement_type_cost
    return (0.1 * calculate_agreement_price)
  end

  def calculate_stamp_duty_type_cost
    return (30000 + (0.06 * calculate_agreement_price))
  end
end
