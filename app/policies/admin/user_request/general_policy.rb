class Admin::UserRequest::GeneralPolicy < Admin::UserRequestPolicy
  # def index? from Admin::UserRequestPolicy

  def edit?
    super
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def note_create?
    create?
  end

  def permitted_attributes(params = {})
    attributes = super + [:subject, :description, :project_id]
    attributes += [:category] if record.new_record?
    attributes += [:department, :priority, :tags, :due_date] if user.role != 'channel_partner'
    attributes += [:alternate_project_unit_id] if %w[admin crm sales superadmin cp channel_partner].include?(user.role) && record.status == 'pending'
    attributes
  end
end
