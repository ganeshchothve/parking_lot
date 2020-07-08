class Admin::Crm::ApiPolicy < Crm::ApiPolicy

  def new?
    %w[superadmin admin].include?(user.role)
  end
end
