class Admin::ClientPolicy < ClientPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin].include?(user.role)
  end

  def asset_create?
    update?
  end

  def index?
    update?
  end

  def create?
    update?
  end

  def permitted_attributes(params = {})
    attributes = super
    if %w[superadmin].include?(user.role)
      attributes += [general_user_request_categories: [], roles_taking_registrations: []]
    end
    attributes.uniq
  end
end
