class BookingDetailSchemePolicy < SchemePolicy
  def new?
    (ProjectUnit.booking_stages.include?(record.project_unit.status) || record.project_unit.status == 'negotiation_failed') && current_client.enable_actual_inventory?(user) && index?
  end

  def edit?

    (%w[admin sales crm cp].include?(user.role)) && (((record.project_unit.status == 'under_negotiation') && %w[disabled].exclude?(record.status)) || (ProjectUnit.booking_stages.include?(record.project_unit.status)))
  end

  def create?
    case user.role
    case 'crm', 'admin', 'superadmin', 'sales', 'cp', 'sales_admin'
      true
    case 'user', 'management_user', 'employee_user'
      record.project_unit.status == 'hold'
    else
      false
    end
  end

  def update?
    (%w[admin sales crm cp].include?(user.role)) && (((record.project_unit.status == 'under_negotiation') && %w[disabled].exclude?(record.status)) || (ProjectUnit.booking_stages.include?(record.project_unit.status)))
  end


  def permitted_attributes params={}
    attributes = [:derived_from_scheme_id, :user_id,:status]

    unless user.buyer? || (ProjectUnit.booking_stages.include?(record.project_unit.status))
      attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end

    attributes += %i[booking_detail_id project_unit_id] if record.new_record?

    if record.draft? || record.under_negotiation?
      attributes += [:event] if record.approver?(user)
    end

    attributes
  end
end
