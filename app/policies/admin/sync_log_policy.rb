class Admin::SyncLogPolicy < SyncLogPolicy
  # def resync? from SyncLogPolicy
  def index?
    true
  end
end
