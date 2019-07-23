class Admin::PortalStagePriorityPolicy < PortalStagePriorityPolicy

  def index?
    user.role?('superadmin')
  end

  def reorder?
    index?
  end
end
