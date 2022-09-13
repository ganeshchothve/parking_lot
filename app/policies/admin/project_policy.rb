class Admin::ProjectPolicy < ProjectPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def asset_create?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def asset_update?
    asset_create?
  end

  def video_create?
    update?
  end

  def video_update?
    video_create?
  end

  def index?
    user.role.in?(%w(channel_partner cp_owner dev_sourcing_manager)) || (!user.buyer? && (user.booking_portal_client.enable_actual_inventory?(user) || enable_incentive_module?(user))) #&& !user.role?('billing_team')
  end

  def third_party_inventory?
    index? && !user.role?('dev_sourcing_manager')
  end

  def show?
    index? && (record.is_active? || user.role?('superadmin'))
  end

  def create?
    update? && %w[superadmin admin].include?(user.role)
  end

  def sync_on_selldo?
    user.role?('superadmin') && record.valid? && record.selldo_client_id.present? && ENV_CONFIG.dig(:selldo, :user_token).present? && ENV_CONFIG.dig(:selldo, :user_email).present? && record.selldo_id.blank?
  end

  def collaterals?
    valid = true
    valid = false if user.role.in?(%w(channel_partner cp_owner)) && !interested_project_present?
    @condition = 'project_not_subscribed' unless valid
    valid
  end

  def ds?
    user.booking_portal_client.enable_actual_inventory?(user) || enable_incentive_module?(user)
  end

  def switch_project?
    user.role.in?(User::SELECTED_PROJECT_ACCESS) && user.project_ids.count > 1
  end

  def permitted_attributes(params = {})
    attributes = [:name, :developer_name, :micro_market, :possession, :latitude, :longitude, :registration_name, :rera_registration_no, :gst_number, :cin_number, :creator_id, :price_starting_from, :price_upto, :logo, :cover_photo, :embed_map_tag, :foyer_link, project_type: [], category: [], project_segment: [], booking_sources: []]

    if user.role.in?(%w(superadmin admin))
      attributes += [:area_unit, :is_active, :cancellation_amount, :blocking_amount, :payment_enabled, :blocking_days, :holding_minutes, :terms_and_conditions, :enable_booking_with_kyc, :enable_inventory, :kylas_product_id, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes, disable_project: [:walk_ins, :bookings, :invoicing], booking_custom_template_ids: []
      ]
    end

    attributes.uniq
  end

  private

  def interested_project_present?
    if record.is_a?(Project)
      user.interested_projects.approved.where(project_id: record.id).present?
    else
      true
    end
  end
end
