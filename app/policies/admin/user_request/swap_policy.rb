class Admin::UserRequest::SwapPolicy < Admin::UserRequestPolicy
  # def index? from Admin::UserRequestPolicy

  def edit?
    super && user.booking_portal_client.enable_actual_inventory?(user)
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:requestable_id, :requestable_type] if record.new_record? && record.status == 'pending' && %w[admin crm sales superadmin cp sales_admin cp_owner channel_partner].include?(user.role)
    attributes += [:alternate_project_unit_id] if %w[admin crm sales superadmin cp channel_partner sales_admin].include?(user.role) && record.status == 'pending'
    attributes
  end
end
