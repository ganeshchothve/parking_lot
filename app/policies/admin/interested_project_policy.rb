class Admin::InterestedProjectPolicy < InterestedProjectPolicy
  def index?
    user.role.in?(%w(channel_partner cp_owner)) && user.active_channel_partner?
  end

  def create?
    index? && record.project&.is_active?
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

  def permitted_attributes(params = {})
    attrs = super
    attrs += [:event] if user.role.in?(%w(channel_partner cp_owner)) && (record.new_record? || record.rejected?)
    attrs += [:event] if user.role.in?(%w(admin superadmin cp cp_admin)) && record.status.in?(%w(subscribed approved blocked))
    attrs.uniq!
    attrs
  end
end

