class Admin::Audit::RecordPolicy < Audit::RecordPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end
end
