class PortalStagePriorityPolicy < ApplicationPolicy

  def index?
    false
  end

  def reorder?
    false
  end
end
