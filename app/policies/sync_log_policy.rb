class SyncLogPolicy < ApplicationPolicy
  # def index? from ApplicationPolicy
  def resync?
    false
  end
end
