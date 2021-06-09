class Admin::LeadPolicy < LeadPolicy

  def index?
    out = !user.buyer?
    out && user.active_channel_partner?
  end

  def export?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def new?
    true
  end

  def edit?
    user.role.in?(%w(superadmin admin))
  end

  def update?
    edit?
  end

  def sync_notes?
    edit?
  end

  def note_create?
    user.role?(:channel_partner) && record.user.role.in?(User::BUYER_ROLES)
  end

  def asset_create?
    %w[admin sales sales_admin crm].include?(user.role)
  end

  def show_selldo_links?
    ENV_CONFIG['selldo'].try(:[], 'base_url').present? && record.lead_id? && current_client.selldo_default_search_list_id?
  end
  
  def send_payment_link?
    record.user.confirmed?
  end

  def permitted_attributes(params = {})
    attributes = super || []
    attributes += [:first_name, :last_name, :email, :phone, :project_id] if record.new_record?
    if user.role.in?(%w(superadmin admin))
      attributes += [:manager_id, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
    end
    attributes.uniq
  end
end
