class Admin::PortalStagePriorityPolicy < PortalStagePriorityPolicy

  def index?
    if current_client.real_estate?
      user.role?('superadmin')
    else
      false
    end
  end

  def reorder?
    index?
  end
end
