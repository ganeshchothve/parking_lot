class Buyer::SyncLogPolicy < SyncLogPolicy
  # def resync? from SyncLogPolicy
  def index?
    false
  end
end
