class AnnouncementPolicy < ApplicationPolicy
  def index?
    user.role.in?(%w(superadmin admin channel_partner cp_owner))
  end
end
