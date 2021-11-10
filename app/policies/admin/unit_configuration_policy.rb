class Admin::UnitConfigurationPolicy < UnitConfigurationPolicy
  def index?
    Admin::ProjectPolicy.new(user, Project.new).index?
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
