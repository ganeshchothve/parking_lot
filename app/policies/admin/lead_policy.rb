class Admin::LeadPolicy < LeadPolicy

  def index?
    out = !user.buyer?
    out = out && user.active_channel_partner?
    out = false if user.role?('channel_partner') && !interested_project_present?
    out
  end

  def export?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def new?
    valid = true
    valid = false if user.role?('channel_partner') && !interested_project_present?
    @condition = 'project_not_subscribed' unless valid
    valid
  end

  def check_and_register?
    new?
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
    ENV_CONFIG['selldo'].try(:[], 'base_url').present? && record.lead_id? && record.project.selldo_default_search_list_id?
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

  private

  def interested_project_present?
    if record.is_a?(Lead) && record.project_id.present?
      user.interested_projects.approved.where(project_id: record.project_id).present?
    else
      true
    end
  end
end
