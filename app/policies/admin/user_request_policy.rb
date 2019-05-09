class Admin::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    valid = permitted_user_role_for_new? && enable_actual_inventory?
    if record.booking_detail.present?
      valid &&= BookingDetail::BOOKING_STAGES.include?(record.booking_detail.status)
    end
    valid
  end

  def edit?
    %w[admin crm sales cp superadmin].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def update?
    edit?
  end

  def export?
    %w[admin superadmin crm].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def asset_create?
    permitted_user_role_for_new? && enable_actual_inventory?
  end

  def permitted_attributes(_params = {})
    attributes = []
    if record.status == 'pending' && %w[admin crm sales superadmin cp].include?(user.role)
      attributes += [:event]
      attributes += [:project_unit_id, :booking_detail_id] if record.new_record?
      attributes += [notes_attributes: Admin::NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes
  end

  private

  def permitted_user_role_for_new?
    return true if %w[superadmin admin crm channel_partner].include?(user.role)
    @condition = 'do_not_have_access'
    false
  end

  def enable_actual_inventory?
    current_client.enable_actual_inventory?(user)
  end
end
