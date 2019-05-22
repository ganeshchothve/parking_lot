class Admin::SyncLogPolicy < SyncLogPolicy
  include ApplicationHelper
  def index?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def resync?
    %w[superadmin admin sales_admin].include?(user.role)
  end
end
