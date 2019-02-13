class Admin::ErpModelPolicy < ErpModelPolicy
  # def edit? from ErpModelPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end

  def update?
    user.role == 'superadmin'
  end

  def permitted_attributes(_params = {})
    attributes = []
    attributes += %i[resource_class domain url request_type http_verb reference_key_name reference_key_location request_payload is_active action_name] if user.role == 'superadmin'
    attributes
  end
end
