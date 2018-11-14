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

  def pending_balance(options={})
    strict = options[:strict] || false
    user_id = options[:user_id] || self.user_id
    if user_id.present?
      receipts_total = Receipt.where(user_id: user_id, project_unit_id: self.id)
      if strict
        receipts_total = receipts_total.where(status: "success")
      else
        receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
      end
      receipts_total = receipts_total.sum(:total_amount)
      return (self.booking_price - receipts_total)
    else
      return nil
    end
  end

  def ageing
    if(["booked_confirmed"].include?(self.status))
      last_booking_payment = self.receipts.in(status:["clearance_pending", "success"]).desc(:created_at).first.created_at.to_date
      due_since = self.receipts.in(status:["clearance_pending", "success"]).asc(:created_at).first.created_at.to_date
      age = (last_booking_payment - due_since).to_i
    elsif(["blocked", "booked_tentative"].include?(self.status))
      age = (Date.today - self.receipts.in(status:["clearance_pending", "success"]).asc(:created_at).first.created_at.to_date).to_i
    else
      return "NA"
    end
    if age < 15
      return "< 15 days"
    elsif age < 30
      return "< 30 days"
    elsif age < 45
      return "< 45 days"
    elsif age < 60
      return "< 60 days"
    else
      return "> 60 days"
    end
  end

  def total_amount_paid
    receipts.where(user_id: self.user_id).where(status: 'success').sum(:total_amount)
  end

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
