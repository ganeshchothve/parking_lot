class ProjectTowerPolicy < ApplicationPolicy

  def asset_create?
    create?
  end
end