class Admin::UnitConfigurationPolicy < UnitConfigurationPolicy
  def index?
    if current_client.real_estate?
      Admin::ProjectPolicy.new(user, Project.new).index? && record&.project&.enable_inventory? && !user.booking_portal_client.launchpad_portal
    else
      false
    end
  end

  def edit?
    Admin::ProjectPolicy.new(user, Project.new).update?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attrs = super
    attrs += [:name]
    attrs
  end
end
