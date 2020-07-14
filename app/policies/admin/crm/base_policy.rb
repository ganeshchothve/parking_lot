class Admin::Crm::BasePolicy < Crm::BasePolicy

  def index?
    %w[superadmin].include?(user.role)
  end
end
