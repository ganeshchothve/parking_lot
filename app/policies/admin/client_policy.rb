class Admin::ClientPolicy < ClientPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin admin].include?(user.role)
  end

  def asset_create?
    update?
  end

  def index?
    update?
  end

  def create?
    update?
  end

  def get_regions?
    show?
  end

  def kylas_api_key?
    user.role.in?(%w(admin superadmin))
  end

  def switch_client?
    user.role.in?(%w(superadmin)) && user.client_ids.count > 1
  end

  def allow_settings?
    user.role?('superadmin')
  end

  def show_marketplace_tenant_id?
    (user.role?('superadmin') && record.is_marketplace?)
  end

  def permitted_attributes(params = {})
    attributes = super
    if %w[superadmin admin].include?(user.role)
      attributes += [:twilio_account_sid, :twilio_auth_token, :twilio_virtual_number, :kylas_api_key]
      attributes += [general_user_request_categories: [], partner_regions: [], roles_taking_registrations: [], mask_lead_data_for_roles: [], team_lead_dashboard_access_roles: []]
    end
    if user.role?('superadmin')
      attributes += [:industry]
    end
    attributes.uniq
  end
end
