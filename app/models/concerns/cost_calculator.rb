module CostCalculator
  def effective_rate
    self.base_rate + self.floor_rise - self.applied_discount_rate
  end

  def discount(user)
    discount_rate(user) * saleable
  end

  def discount_rate(user)
    user = self.user if self.user_id.present?
    if applied_discount_id.present? && applied_discount_rate.present?
      return applied_discount_rate
    else
      discount_obj = applicable_discount(user)
      discount = (discount_obj.present? ? discount_obj.value : 0)
      e_discount = 0
      if user.role?("employee_user") || user.role?("management_user")
        #e_discount = ((base_rate > 4100) ? (base_rate - 4100) : 0)
        e_discount = base_rate*0.05
      end
      return (discount > e_discount ? discount : e_discount)
    end
    0
  end

  def applicable_discount(user)
    selector = []
    selector << {user_id: user.id} if user.present?
    selector << {user_role: user.role} if user.present?
    selector << {project_unit_id: self.id}
    discount_obj = Discount.where(status: "approved").or(selector).desc(:value).first
  end

  def blocking_payment
    receipts.where(payment_type: 'blocking').first
  end

  def booking_price
    (agreement_price * booking_price_percent_of_agreement_price).to_i
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
      last_booking_payment = self.receipts.where(status:"success").desc(:created_at).first.created_at.to_date
      due_since = self.receipts.where(status:"success").asc(:created_at).first.created_at.to_date
      age = (last_booking_payment - due_since).to_i
    elsif(["blocked", "booked_tentative"].include?(self.status))
      age = (Date.today - self.receipts.where(status:"success").asc(:created_at).first.created_at.to_date).to_i
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
    receipts.where(status: 'success').sum(:total_amount)
  end

  def calculate_agreement_price
    base_price + self.costs.where(category: 'agreement').collect{|x| x.value}.sum
  end
  def base_price
    saleable * effective_rate
  end
end
