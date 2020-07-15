class Admin::Crm::BasePolicy < Crm::BasePolicy

  def index?
    %w[superadmin].include?(user.role) && current_client.external_api_integration?
  end

  def choose_crm?
    %w[superadmin admin sales].include?(user.role) && current_client.external_api_integration?
  end
end
