class Buyer::UserRequest::SwapPolicy < Buyer::UserRequestPolicy
  # def index? from Buyer::UserRequestPolicy

  def edit?
    super && current_client.enable_actual_inventory?(user)
  end

  def new?
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
    attributes += [:alternate_project_unit_id] if record.status == 'pending' && (user.buyer? && record.user_id == user.id)
    attributes
  end
end
