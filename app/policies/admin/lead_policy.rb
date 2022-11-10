class Admin::LeadPolicy < LeadPolicy

  def index?
    if user.role?(:superadmin)
      out = !(user.buyer? || user.role.in?(%w(dev_sourcing_manager))) && user.selected_client.enable_leads?
    else
      out = !(user.buyer? || user.role.in?(%w(dev_sourcing_manager))) && user.booking_portal_client.enable_leads?
    end
    # out = !(user.buyer? || user.role.in?(%w(channel_partner cp_owner dev_sourcing_manager)))
    #out = out && user.active_channel_partner?
    #out = false if user.role.in?(%w(channel_partner cp_owner)) && !interested_project_present?
    #out
  end

  def ds_index?
    out = !(user.buyer? || user.role.in?(%w(dev_sourcing_manager)))
    out = out && user.active_channel_partner?
    out = false if user.role.in?(%w(channel_partner cp_owner)) && !interested_project_present?
    out
  end

  def search_inventory?
    index?
  end

  def export?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def new?(current_project_id = nil)
    valid = true && user.role.in?(%w(superadmin admin gre crm account_manager account_manager_head) + User::CHANNEL_PARTNER_USERS + User::SALES_USER)
    valid = false if user.present? && user.role.in?(%w(channel_partner cp_owner)) && !(user.active_channel_partner? && interested_project_present?)
    valid = valid && project_access_allowed?(current_project_id)
    @condition = 'project_not_subscribed' unless valid
    if record.is_a?(Lead)
      if !(record.project.is_active?)
        @condition = 'project_not_active'
        valid = false
      elsif !(record.project&.walk_ins_enabled?)
        @condition = 'walkin_disabled'
        valid = false
      else
        valid
      end
    end
    valid
  end

  def check_and_register?
    new?
  end

  def edit?
    user.role.in?(%w(superadmin admin gre))
  end

  def update?
    edit?
  end

  def sync_notes?
    edit?
  end

  def note_create?
    user.role.in?(%w(superadmin admin channel_partner cp_owner sales sales_admin)) && record.user.role.in?(User::BUYER_ROLES)
  end

  def asset_create?
    valid = %w[admin sales sales_admin crm].include?(user.role)
    # if user.role?(:sales) && is_assigned_lead?
    #   valid = is_lead_accepted? && valid
    # end
    valid
  end

  def is_lead_accepted?
    if user.role?(:sales) && record.is_a?(Lead)
      record.accepted_by_sales?
    else
      false
    end
  end

  def is_assigned_lead?
    if user.role?(:sales) && record.is_a?(Lead)
      Lead.where(id: record.id, closing_manager_id: user.id).in(customer_status: %w(engaged)).first.present?
    else
      false
    end
  end

  def show_selldo_links?
    ENV_CONFIG['selldo'].try(:[], 'base_url').present? && record.lead_id? && record.project.selldo_default_search_list_id?
  end

  def send_payment_link?
    record.user.confirmed? && user.role.in?(User::ADMIN_ROLES) && (user.booking_portal_client.enable_payment_with_kyc ? record.kyc_ready? : true )
  end

  def search_by?
    user.role.in?(%w(sales sales_admin gre team_lead))
  end

  def assign_sales?
    user.role.in?(%w(gre team_lead))
  end

  def move_to_next_state?
    if user.role?('sales')
      record.may_dropoff? && (record.closing_manager_id == user.id)
    else
      (user.role.in?(%w(gre team_lead)) && (record.is_a?(Lead) || record.role?('sales'))) ||
      user.role?('sales') && (
        (!record.is_a?(Lead) && record.role?('sales') && (record.may_break? || record.may_available?))
      )
    end
  end

  def show_existing_customer?
    %w(sales).exclude?(user.role) && (user.booking_portal_client.enable_leads || user.booking_portal_client.enable_site_visit?)
  end

  def reassign_lead?
    user.booking_portal_client.team_lead_dashboard_access_roles.include?(user.role) || user.role?("team_lead")
  end

  def reassign_sales?
    reassign_lead?
  end

  def accept_lead?
    %w(sales).include?(user.role)
  end

  def new_kylas_associated_lead?
    %w(superadmin admin sales sales_admin).include?(user.role)
  end

  def create_kylas_associated_lead?
    new_kylas_associated_lead?
  end

  def deal_associated_contact_details?
    new_kylas_associated_lead?
  end

  def new_kylas_lead?
    user.role.in?(%w(admin sales sales_admin))
  end

  def create_kylas_lead?
    new_kylas_lead?
  end

  def permitted_attributes(params = {})
    attributes = super || []
    attributes += [:first_name, :last_name, :email, :phone, :project_id, site_visits_attributes: Pundit.policy(user, [:admin, SiteVisit.new]).permitted_attributes] if record.new_record?
    if user.present? && user.role.in?(%w(superadmin admin gre sales sales_admin))
      attributes += [:manager_id] if user.booking_portal_client.try(:enable_channel_partners?)
      attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
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
