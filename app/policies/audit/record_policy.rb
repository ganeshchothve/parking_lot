class Audit::RecordPolicy < ApplicationPolicy
  def index?
    false
  end
end
