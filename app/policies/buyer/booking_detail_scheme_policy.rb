class Buyer::BookingDetailSchemePolicy < BookingDetailSchemePolicy

  def new?
    only_for_buyer! && enable_actual_inventory? && is_approved_scheme? && is_project_unit_hold?
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

    if record.draft?
      attributes += [:event] if record.approver?(user)
    end

    attributes
  end
end
