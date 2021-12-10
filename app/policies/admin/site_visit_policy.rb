class Admin::SiteVisitPolicy < SiteVisitPolicy
  def index?
    out = user.role.in?(%w(admin superadmin dev_sourcing_manager) + User::CHANNEL_PARTNER_USERS)
    out && user.active_channel_partner?
  end

  def export?
    %w[superadmin admin cp_admin cp].include?(user.role)
  end

  def edit?
    (%w[superadmin admin] + User::CHANNEL_PARTNER_USERS).include?(user.role)
  end

  def new?
    SiteVisit.where(lead_id: record.lead_id, status: 'scheduled').blank? && edit?
  end

  def update?
    edit?
  end

  def create?
    new?
  end

  def change_state?
    user.role.in?(%w(cp_owner channel_partner dev_sourcing_manager))
  end

  def sync_with_selldo?
    user.role.in?(%w(superadmin admin)) && ENV_CONFIG.dig(:selldo, :base_url).present? && record.project.selldo_client_id.present? && record.project.selldo_api_key.present?# && !user.role?('dev_sourcing_manager')
  end

  def note_create?
    user.role.in?(%w(dev_sourcing_manager) + User::CHANNEL_PARTNER_USERS)
  end

  def permitted_attributes params={}
    attributes = super || []
    attributes += [:manager_id] if record.new_record? && user.role.in?(%w(cp_owner channel_partner))
    attributes += [:event] if record.scheduled? && user.role.in?(%w(cp_owner channel_partner)) && current_client.launchpad_portal?
    attributes += [:approval_event] if record.approval_status.in?(%w(pending rejected)) && user.role.in?(%w(dev_sourcing_manager)) && current_client.launchpad_portal?
    attributes
  end
end
