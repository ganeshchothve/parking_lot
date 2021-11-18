class Admin::InterestedProjectPolicy < InterestedProjectPolicy
  def index?
    create?
  end

  def create?
    user.role?('channel_partner') && user.active_channel_partner?
  end

  def edit?
    user.role.in?(%w(admin superadmin))
  end

  def update?
    edit?
  end

  def permitted_attributes(params = {})
    attrs = super
    attrs += [:event] if user.role?('channel_partner') && (record.new_record? || record.rejected?)
    attrs += [:event] if user.role.in?(%w(admin superadmin cp cp_admin)) && record.status.in?(%w(subscribed approved blocked))
    attrs.uniq!
    attrs
  end
end

