class Admin::Crm::BasePolicy < Crm::BasePolicy

  def index?
    %w[superadmin].include?(user.role)
  end

  def choose_crm?
    %w[superadmin admin sales].include?(user.role)
  end
end
