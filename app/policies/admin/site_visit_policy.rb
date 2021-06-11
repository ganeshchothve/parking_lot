class Admin::SiteVisitPolicy < SiteVisitPolicy
  def index?
    out = !user.buyer?
    out && user.active_channel_partner?
  end

  def edit?
    %w[superadmin admin sales_admin channel_partner].include?(user.role)
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

  def sync_with_selldo?
    edit? && ENV_CONFIG.dig(:selldo, :base_url).present? && record.project.selldo_client_id.present? && record.project.selldo_api_key.present?
  end
end
