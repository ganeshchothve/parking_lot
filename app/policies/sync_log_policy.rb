class SyncLogPolicy < ApplicationPolicy
  # def index? from ApplicationPolicy

  def resync?
    true
  end
end
