class Admin::Crm::ApiPolicy < Crm::ApiPolicy

  def new?
    %w[superadmin].include?(user.role)
  end
end
