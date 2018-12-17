class Admin::AuditEntryPolicy < ApplicationPolicy
  def show?
    %w[superadmin admin].include?(user.role)
  end
end
