class BookingDetailSchemePolicy < SchemePolicy
  # def new?
  #   (ProjectUnit.booking_stages.include?(record.project_unit.status) || record.project_unit.status == 'negotiation_failed') && current_client.enable_actual_inventory?(user) && index?
  # end

  # def edit?
  #   (%w[admin sales crm cp sales_admin].include?(user.role)) && (((record.project_unit.status == 'under_negotiation') && %w[disabled].exclude?(record.status)) || (ProjectUnit.booking_stages.include?(record.project_unit.status)))
  # end

  # def create?
  #   case user.role
  #   when 'crm', 'admin', 'superadmin', 'sales', 'cp', 'sales_admin'
  #     true
  #   when 'user', 'management_user', 'employee_user'
  #     record.project_unit.status == 'hold'
  #   else
  #     false
  #   end
  # end

  # def update?
  #   case user.role
  #   when 'admin', 'sales', 'crm', 'cp', 'sales_admin'
  #     if %w( hold under_negotiation).include?(record.project_unit.status)
  #       if %w[disabled].exclude?(record.status)
  #         true
  #       else
  #         @condition = 'scheme_id_disabled'
  #         false
  #       end
  #     elsif ProjectUnit.booking_stages.include?(record.project_unit.status)
  #       true
  #     else
  #       @condition = 'project_unit_status_missing'
  #       false
  #     end
  #   when 'user', 'management_user', 'employee_user'
  #     if record.project_unit.status == 'hold' && %w[disabled].exclude?(record.status)
  #       true
  #     else
  #       @condition = 'scheme_id_disabled'
  #     end
  #   else
  #     @condition = 'project_unit_status_missing'
  #     false
  #   end
  #   # (%w[admin sales crm cp].include?(user.role)) && ((( %(under_negotiation hold).include?(record.project_unit.status) ) && %w[disabled].exclude?(record.status)) || (ProjectUnit.booking_stages.include?(record.project_unit.status)))
  # end

  # def permitted_attributes params={}
  #   attributes = [:derived_from_scheme_id, :user_id,:status]

  #   unless user.buyer? || (ProjectUnit.booking_stages.include?(record.project_unit.status))
  #     attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
  #   end

  #   attributes += %i[booking_detail_id project_unit_id] if record.new_record?

  #   if record.draft? || record.under_negotiation?
  #     attributes += [:event] if record.approver?(user)
  #   end

  #   attributes
  # end

  private

  def check_booking_detail_state
    return false if record.booking_detail.status.in?(%w[swapped cancelled scheme_rejected])
    true
  end
  
  def is_project_unit_hold?
    return true if record.booking_detail.hold?
    @condition = 'only_under_hold'
    false
  end

  def can_add_new_bd_scheme?
    return true if %w[hold scheme_rejected].include?(record.booking_detail.status)
    @condition = 'booking_detail_scheme_present'
    false
  end

  def is_this_user_added_by_channel_partner?
    return true if record.booking_detail.user.manager_id == user.id
    @condition = 'do_not_have_access'
    false
  end

  def is_cross_tower_scheme?
    return true if record.project_unit.project_tower_id == record.project_tower_id
    @condition = 'cross_project_tower'
    false
  end

  def is_derived_from_scheme_approved?
    if record.new_record?
      if record.derived_from_scheme.status == 'approved'
        return true
      else
        @condition = 'scheme_is_not_approved'
        return false
      end
    else
      return true
    end
  end
end
