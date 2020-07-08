class Admin::ApiLogPolicy < AccountPolicy

  def index?
    %w[superadmin].include?(user.role)
  end
end
