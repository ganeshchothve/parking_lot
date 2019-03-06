class Buyer::BookingDetailSchemePolicy < BookingDetailSchemePolicy

  def new?
    if user.buyer?
      if current_client.enable_actual_inventory?(user)
        if %w[disabled].exclude?(record.status)
          if record.project_unit.status == 'hold'
            true
          else
            @condition = 'only_for_hold_project_unit'
            false
          end
        else
          @condition = 'disabled_scheme'
          false
        end
      else
        @condition = 'enable_actual_inventory'
        false
      end
    else
      @condition = 'only_buyer'
      false
    end
  end

  def edit?
    new?
  end

  def create?
    new?
  end

  def update?
    new?
  end

  def permitted_attributes params={}
    attributes = [:derived_from_scheme_id, :status]

    if record.draft? || record.under_negotiation?
      attributes += [:event] if record.approver?(user)
    end

    attributes
  end
end
