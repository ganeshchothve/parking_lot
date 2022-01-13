class Admin::BookingDetailSchemePolicy < BookingDetailSchemePolicy

  # BOOKING_ALLOWED_USERS = %w(admin sales sales_admin crm channel_partner)

  def new?
    record.project&.is_active? && only_for_admin! && enable_actual_inventory? && can_add_new_bd_scheme?
  end

  def create?
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

  def edit?
    if record.project&.is_active? && only_for_admin! && enable_actual_inventory? && is_booking_detail_ready_for_change? && is_derived_from_scheme_approved? && check_booking_detail_state?
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

  #
  # If Booking detail has several state where admin can update or edit related scheme.
  #
  #
  def is_booking_detail_ready_for_change?
    return true if %w(hold blocked booked_tentative booked_confirmed under_negotiation scheme_approved).include?(record.booking_detail.status)
    @condition = 'booking_detail_is_not_ready'
    false
  end

end
