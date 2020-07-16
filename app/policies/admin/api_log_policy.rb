class Admin::ApiLogPolicy < AccountPolicy

  def index?
    %w[superadmin admin sales].include?(user.role)
  end
end
