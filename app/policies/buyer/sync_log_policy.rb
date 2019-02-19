class Buyer::SyncLogPolicy < SyncLogPolicy
  # def resync? from SyncLogPolicy
  def index?
    user.buyer?
  end
end
