class Admin::UserRequest::GeneralPolicy < Admin::UserRequestPolicy
  # def index? from Admin::UserRequestPolicy

  def edit?
    (super || %w(cp_admin cp channel_partner billing_team).include?(user.role)) && %w(resolved rejected).exclude?(record.status)
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
    attributes += [:department, :priority, :due_date, tags: []] if user.role != 'channel_partner'
    attributes += [:assignee_id] if %w[admin crm sales superadmin cp channel_partner cp_admin billing_team].include?(user.role) && record.status == 'pending'
    attributes
  end
end
