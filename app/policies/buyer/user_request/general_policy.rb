class Buyer::UserRequest::GeneralPolicy < Buyer::UserRequestPolicy
  # def index? from Buyer::UserRequestPolicy

  def edit?
    super
  end

  def new?
    super
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
