class Admin::SiteVisitPolicy < SiteVisitPolicy
  def index?
    out = user.role.in?(%w(admin superadmin dev_sourcing_manager channel_partner cp_owner billing_team sales sales_admin))
    out && user.active_channel_partner? && current_client.enable_site_visit?
  end

  def export?
    unless marketplace_client?
      %w[superadmin admin cp_admin cp].include?(user.role)
    else
      %w[superadmin admin].include?(user.role)
    end
  end

  def edit?
    (%w[superadmin admin] + User::CHANNEL_PARTNER_USERS).include?(user.role) && record.project.is_active?
  end

  def new?(current_project_id = nil)
    valid = current_client.enable_site_visit?
    valid = valid && SiteVisit.where(booking_portal_client_id: record.booking_portal_client_id, lead_id: record.lead_id, status: 'scheduled').blank? && edit? && record.project.walk_ins_enabled?
    valid = valid && project_access_allowed?(current_project_id)
    valid
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
      (user.role.in?(%w(cp_owner channel_partner dev_sourcing_manager)) && record.scheduled? && record.may_conduct?) ||
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

  def show_channel_partner_column?
    !user.role.in?(%w(channel_partner))
  end

  def show_channel_partner_user?
    record.manager.present? && record.manager.channel_partner? && record.manager_name.present?# && user.role.in?(User::ALL_PROJECT_ACCESS)
  end

  def permitted_attributes params={}
    attrs = super || []
    if user.present?
      if record.new_record?
        attrs += [:manager_id] if user.role.in?(%w(cp_owner channel_partner))
      else
        attrs += [:event] if record.scheduled? && user.role.in?(%w(cp_owner channel_partner))
        attrs += [:event] if record.may_paid? && user.role.in?(%w(superadmin admin cp_admin))
        attrs += [:approval_event] if record.approval_status.in?(%w(pending rejected)) && user.role.in?(%w(dev_sourcing_manager))
        attrs += [:rejection_reason] if user.role?(:dev_sourcing_manager)
      end
    end
    attrs
  end
end
