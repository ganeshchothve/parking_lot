class SyncLogPolicy < ApplicationPolicy
  # def index? from ApplicationPolicy

  def index?
    false
  end

  def resync?
    false
  end
end
