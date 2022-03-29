class Admin::SiteVisitPolicy < SiteVisitPolicy
  def index?
    out = user.role.in?(%w(admin superadmin dev_sourcing_manager billing_team) + User::CHANNEL_PARTNER_USERS)
    out && user.active_channel_partner?
  end

  def export?
    %w[superadmin admin cp_admin cp].include?(user.role)
  end

  def edit?
    (%w[superadmin admin] + User::CHANNEL_PARTNER_USERS).include?(user.role) && record.project.is_active?
  end

  def new?
    SiteVisit.where(lead_id: record.lead_id, status: 'scheduled').blank? && edit? && record.project.walk_ins_enabled?
  end

  def update?
    edit?
  end

  def create?
    new?
  end

  def change_state?
    record.project.is_active? &&
    (
      (user.role.in?(%w(cp_owner channel_partner dev_sourcing_manager)) && record.scheduled?) ||
      (user.role.in?(%w(superadmin admin cp_admin)) && record.may_paid?) ||
      (user.role.in?(%w(dev_sourcing_manager)) && record.approval_status.in?(%w(pending rejected)))
    )
  end

  def reject?
    user.role?('dev_sourcing_manager') && record.verification_pending?
  end

  def sync_with_selldo?
    record.project.is_active? && user.role.in?(%w(superadmin admin)) && ENV_CONFIG.dig(:selldo, :base_url).present? && record.project.selldo_client_id.present? && record.project.selldo_api_key.present? && record.lead&.push_to_crm?# && !user.role?('dev_sourcing_manager')
  end

  def note_create?
    user.role.in?(%w(dev_sourcing_manager) + User::CHANNEL_PARTNER_USERS)
  end

  def permitted_attributes params={}
    attributes = super || []
    attributes += [:manager_id] if record.new_record? && user.role.in?(%w(cp_owner channel_partner))
    attributes += [:event] if record.scheduled? && user.role.in?(%w(cp_owner channel_partner)) && current_client.launchpad_portal?
    attributes += [:event] if record.may_paid? && user.role.in?(%w(superadmin admin cp_admin))
    attributes += [:approval_event] if record.approval_status.in?(%w(pending rejected)) && user.role.in?(%w(dev_sourcing_manager)) && current_client.launchpad_portal?
    attributes += [:rejection_reason] if user.role?(:dev_sourcing_manager)
    attributes
  end
end
