class Admin::SyncLogPolicy < SyncLogPolicy
  def index?
    true
  end

  def resync?
    %w[superadmin admin sales_admin].include?(user.role)
  end
end
