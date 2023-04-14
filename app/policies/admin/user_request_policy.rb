class Admin::UserRequestPolicy < UserRequestPolicy
  # def index? from UserRequestPolicy

  def new?
    new_permission_by_requestable_type
  end

  def edit?
    %w[admin crm sales cp superadmin sales_admin].include?(user.role) && user.booking_portal_client.enable_actual_inventory?(user) && !%w(rejected resolved).include?(record.status)
  end

  def update?
    edit?
  end

  def export?
    unless marketplace_client?
      %w[admin superadmin crm].include?(user.role) && user.booking_portal_client.enable_actual_inventory?(user)
    else
      %w[superadmin admin].include?(user.role) && user.booking_portal_client.enable_actual_inventory?(user)
    end
  end

  def asset_create?
    true
  end

  def permitted_attributes(_params = {})
    attributes = []
    access_status = (record.status == 'pending' && ["UserRequest::Cancellation", "UserRequest::Swap"].include?(record._type))
    access_status = access_status || (['pending', 'processing'].include?(record.status) && record._type == "UserRequest::General")
    if access_status && %w[admin crm sales_admin sales superadmin cp cp_admin billing_team].include?(user.role)
      attributes += [:event, :reason_for_failure]
    end
    if access_status && %w[sales_admin].include?(user.role) && !user.booking_portal_client.launchpad_portal
      attributes += [:event, :reason_for_failure]
    end
    if %w[admin crm superadmin cp channel_partner cp_admin billing_team].include?(user.role)
      attributes += [notes_attributes: Admin::NotePolicy.new(user, Note.new).permitted_attributes]
    end
    attributes.uniq
  end
end
