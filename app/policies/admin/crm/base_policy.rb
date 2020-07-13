class Admin::Crm::BasePolicy < Crm::BasePolicy

  def index?
    %w[superadmin admin].include?(user.role)
  end
end
