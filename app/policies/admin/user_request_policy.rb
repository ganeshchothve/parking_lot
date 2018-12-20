class Admin::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    valid = true
    valid = (record.project_unit.user_based_status(user) == 'booked' && record.project_unit.status != 'hold') && UserRequest.where(project_unit_id: record.project_unit_id).where(status: 'pending').blank? if record.project_unit_id.present?
    valid &&= %w[superadmin admin crm].include?(user.role)
  end

  def edit?
    %w[admin crm sales cp superadmin].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def export?
    %w[admin superadmin crm].include?(user.role) && current_client.enable_actual_inventory?(user)
  end

  def permitted_attributes(_params = {})
    attributes = []
    if record.status == 'pending' && %w[admin crm sales superadmin cp].include?(user.role)
      attributes += [:project_unit_id] if record.new_record?
      attributes += [:status] if record.persisted?
      attributes += [notes_attributes: NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes
  end
end
