class Admin::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    permitted_user_role_for_new? && enable_actual_inventory? && new_permission_by_requestable_type
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
      attributes += [:event, :reason_for_failure]
      attributes += [:requestable_id, :requestable_type] if record.new_record?
      attributes += [notes_attributes: Admin::NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes
  end

  private

  def permitted_user_role_for_new?
    return true if user.role != 'channel_partner'
    @condition = 'do_not_have_access'
    false
  end

  def enable_actual_inventory?
    current_client.enable_actual_inventory?(user)
  end
end
