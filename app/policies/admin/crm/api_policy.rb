class Admin::Crm::ApiPolicy < Crm::ApiPolicy

  def new?
    %w[superadmin].include?(user.role)
  end

  def show_response?
    %w[superadmin admin sales].include?(user.role)
  end
end
