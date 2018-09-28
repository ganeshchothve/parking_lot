class BookingDetailSchemePolicy < SchemePolicy
  def edit?
    ["blocked", "booked_tentative"].include?(record.booking_detail.status) && (user.role?('superadmin') || user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp'))
  end

  def permitted_attributes params={}
    [:name, :cost_sheet_template_id, :payment_schedule_template_id, :derived_from_scheme_id, payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
  end
end
