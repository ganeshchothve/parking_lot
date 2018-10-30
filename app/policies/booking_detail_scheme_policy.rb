class BookingDetailSchemePolicy < SchemePolicy
  def edit?
    ["approved", "disabled"].exclude?(record.status) && (user.role?('superadmin') || user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp'))
  end

  def permitted_attributes params={}
    attributes = [:name, :project_tower_id, :user_id, :project_unit_id, :project_id, :user_id, :user_role, :cost_sheet_template_id, :payment_schedule_template_id, :derived_from_scheme_id, payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]

    if record.new_record?
      attributes += [:booking_detail_id]
    end

    if record.draft?
      attributes += [:event] if record.approver?(user)
    end

    attributes
  end
end
