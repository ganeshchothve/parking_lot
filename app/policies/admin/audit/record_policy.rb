class Admin::Audit::RecordPolicy < ApplicationPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end
end
