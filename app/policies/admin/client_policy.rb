class Admin::ClientPolicy < ClientPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin].include?(user.role)
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

  def permitted_attributes(params = {})
    attributes = super
    if %w[superadmin].include?(user.role)
      attributes += [:twilio_account_sid, :twilio_auth_token, :twilio_virtual_number]
      attributes += [general_user_request_categories: [], partner_regions: [], roles_taking_registrations: [], mask_lead_data_for_roles: []]
    end
    attributes.uniq
  end
end
