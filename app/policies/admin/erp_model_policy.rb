class Admin::ErpModelPolicy < ErpModelPolicy
  # def edit? from ErpModelPolicy
  def index?
    %w[superadmin].include?(user.role)
  end

  def new?
    create?
  end

  def create?
    user.role.in? %w(superadmin)
  end

  def update?
    user.role.in? %w(superadmin)
  end

  def permitted_attributes(_params = {})
    attributes = []
    attributes += %i[resource_class domain url request_type http_verb reference_key_name reference_key_location request_payload is_active action_name] if user.role == 'superadmin'
    attributes
  end
end
