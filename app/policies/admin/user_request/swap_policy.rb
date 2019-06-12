class Admin::UserRequest::SwapPolicy < Admin::UserRequestPolicy
  # def index? from Admin::UserRequestPolicy

  def edit?
    super && current_client.enable_actual_inventory?(user)
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:alternate_project_unit_id] if %w[admin crm sales superadmin cp channel_partner].include?(user.role) && record.status == 'pending'
    attributes
  end
end
