class Admin::BookingDetailSchemePolicy < BookingDetailSchemePolicy

  # BOOKING_ALLOWED_USERS = %w(admin sales sales_admin crm channel_partner)

  def new?
    if only_for_admin!
      if record.project_unit.project_tower_id == record.project_tower_id
        if is_project_unit_hold?
          case user.role
          when 'admin', 'sales', 'sales_admin', 'crm'
            true
          when 'channel_partner'
            is_this_user_added_by_channel_partner?
          else
            @condition = 'do_not_have_access'
            false
          end
        end
      else
        @condition = 'cross_project_tower'
        false
      end
    end
  end

  def create?
    new?
  end

  def edit?
    new?
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

    if record.draft? || record.under_negotiation?
      attributes += [:event ] if record.approver?(user)
    end

    attributes
  end

  private

  def is_project_unit_hold?
    return true if record.project_unit.status == 'hold'
    @condition = 'only_under_hold'
    false
  end

  def is_this_user_added_by_channel_partner?
    return true if record.project_unit.user.manager_id == user.id
    @condition = 'do_not_have_access'
    false
  end

end
