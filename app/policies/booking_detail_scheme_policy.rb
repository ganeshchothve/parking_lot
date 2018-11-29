class BookingDetailSchemePolicy < SchemePolicy
  def new?
    (ProjectUnit.booking_stages.include?(record.project_unit.status) || record.project_unit.status == "negotiation_failed") && current_client.enable_actual_inventory?(user) && index?
  end

  def edit?
    ["approved", "disabled"].exclude?(record.status) && (user.role?('superadmin') || user.role?('admin') || user.role?('sales') || user.role?('crm') || user.role?('cp'))
  end

  def permitted_attributes params={}
    attributes = [:derived_from_scheme_id, :user_id]

    if !user.buyer?
      attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end

    if record.new_record?
      attributes += [:booking_detail_id, :project_unit_id]
    end

    if record.draft? || record.under_negotiation?
      attributes += [:event] if record.approver?(user)
    end

    attributes
  end
end
