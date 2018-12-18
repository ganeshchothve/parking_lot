class Admin::Audit::EntryPolicy < ApplicationPolicy
  def show?
    %w[superadmin admin].include?(user.role)
  end
end
