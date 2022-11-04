class Admin::ApiLogPolicy < AccountPolicy

  def index?
    %w[superadmin admin].include?(user.role)
  end
end
