class Admin::BookingDetailSchemePolicy < BookingDetailSchemePolicy

  # BOOKING_ALLOWED_USERS = %w(admin sales sales_admin crm channel_partner)

  def new?
    if only_for_admin! && enable_actual_inventory? && is_cross_tower_scheme?  &&  is_derived_from_scheme_approved? && can_add_new_bd_scheme? 
      case user.role
      when 'admin', 'sales', 'sales_admin', 'crm', 'superadmin'
        true
      when 'channel_partner'
        is_this_user_added_by_channel_partner?
      else
        @condition = 'do_not_have_access'
        false
      end
    end
  end

  def create?
    new?
  end

  def edit?
    if only_for_admin! && enable_actual_inventory? && is_derived_from_scheme_approved? && check_booking_detail_state
      case user.role
      when 'admin', 'sales', 'sales_admin', 'crm', 'superadmin' 
        true
      when 'channel_partner'
        if is_this_user_added_by_channel_partner?
          is_project_unit_hold?
        end
      else
        @condition = 'do_not_have_access'
        false
      end
    end
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [ :derived_from_scheme_id ]
    if user.role?('admin')
      attributes << [:status]
    end

    if %w(admin sales sales_admin crm).include?(user.role)
      attributes += [payment_adjustments_attributes: PaymentAdjustmentPolicy.new(user, PaymentAdjustment.new).permitted_attributes]
    end

    if record.draft? && !(record.new_record?)
      attributes += [:event ] if record.approver?(user)
    end

    attributes
  end

end
