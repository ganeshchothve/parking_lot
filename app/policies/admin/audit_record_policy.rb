class Admin::AuditRecordPolicy < ApplicationPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end
end
