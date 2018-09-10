class UserRequest::SwapPolicy < UserRequestPolicy
  def index?
    super && current_client.enable_actual_inventory?(user)
  end

  def edit?
    super && current_client.enable_actual_inventory?(user)
  end

  def new?
    super && current_client.enable_actual_inventory?(user)
  end

  def export?
    super && current_client.enable_actual_inventory?(user)
  end

  def create?
    super && current_client.enable_actual_inventory?(user)
  end

  def update?
    super && current_client.enable_actual_inventory?(user)
  end

  def permitted_attributes params={}
    attributes = super
    if record.status == "pending"
      attributes += [:alternate_project_unit_id] if ['admin', 'crm', 'sales', 'superadmin', 'cp'].include?(user.role) || (user.buyer? && record.user_id == user.id)
    end
    attributes
  end
end
