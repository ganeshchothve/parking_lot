class Buyer::InterestedProjectPolicy < InterestedProjectPolicy
  def index?
    false
  end

  def create?
    index? && record.project&.is_active? && record.project.walk_ins_enabled?
  end

  def subscribe_projects?
    user.role.in?(%w(channel_partner cp_owner)) && user.active_channel_partner?
  end

  def edit?
    user.role.in?(%w(admin superadmin))
  end

  def update?
    edit?
  end

  def report?
    user.role.in?(%w(cp cp_admin admin superadmin))
  end
end

