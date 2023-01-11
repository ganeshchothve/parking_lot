class Admin::Crm::BasePolicy < Crm::BasePolicy

  def index?
    %w[superadmin].include?(user.role) && user.booking_portal_client.external_api_integration?
  end

  def choose_crm?
    %w[superadmin admin].include?(user.role) && user.booking_portal_client.external_api_integration?
  end
end
