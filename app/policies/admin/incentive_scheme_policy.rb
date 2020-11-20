class Admin::IncentiveSchemePolicy < ApplicationPolicy

  def index?
    user.role.in?(%w(superadmin admin))
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:name, :starts_on, :ends_on, :ladder_strategy, :project_id, :project_tower_id, ladders_attributes: LadderPolicy.new(user, Ladder.new()).permitted_attributes]
  end
end
