class Audit::EntryPolicy < ApplicationPolicy
  def show?
    false
  end
end
