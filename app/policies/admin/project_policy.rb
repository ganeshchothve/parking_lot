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

  def new?
    user.role.in?(%w(superadmin sales_admin))
  end

  def create?
    new?
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

  def sync_kylas_product?
    user.booking_portal_client.kylas_tenant_id.present?
  end

  def permitted_attributes(params = {})
    attributes = [:name, :developer_name, :micro_market, :city, :possession, :latitude, :longitude, :foyer_link, :kylas_product_id, :launched_on, :our_expected_possession, :total_buildings, :total_units, :description, :advantages, :video_link, :registration_name, :rera_registration_no, :gst_number, :cin_number, :website_link, :creator_id, :support_name, :support_mail, :support_phone, :price_starting_from, :price_upto, :project_size, :total_buildings, :logo, :mobile_cover_photo, :cover_photo, :mobile_logo, :embed_map_tag, project_type: [], category: [], project_segment: [], approved_banks: [], configurations: [], amenities: [], usp: [], broker_usp: [], booking_custom_template_ids: [], specifications_attributes: SpecificationPolicy.new(user, Specification.new).permitted_attributes, offers_attributes: OfferPolicy.new(user, Offer.new).permitted_attributes, timeline_updates_attributes: TimelineUpdatePolicy.new(user, TimelineUpdate.new).permitted_attributes, address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, nearby_locations_attributes: NearbyLocationPolicy.new(user, NearbyLocation.new).permitted_attributes]

    if user.role?(:superadmin)
      attributes += [
        :selldo_client_id, :selldo_id, :selldo_default_search_list_id, :selldo_form_id, :selldo_gre_form_id,
        :selldo_channel_partner_form_id, :selldo_api_key, :selldo_default_srd, :selldo_cp_srd,
        :allowed_bookings_per_user, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag,
        :notification_email, :notification_numbers, :sender_email, :area_unit, :is_active,
        :support_number, :support_email, :channel_partner_support_number, :channel_partner_support_email,
        :cancellation_amount, :blocking_amount, :region, :sv_incentive, :spot_booking_incentive,
        :pre_reg_incentive_percentage, :pre_reg_min_bookings, :iris_url, :payment_enabled,
        :blocking_days, :enable_slot_generation,
        :holding_minutes, :terms_and_conditions, :email_header, :email_footer, :hot, :enable_inventory,
        :enable_booking_with_kyc, :gst_slab_applicable, :check_sv_availability_in_selldo,
        :consideration_value_help_text, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes,
        email_domains: [], booking_portal_domains: [], enable_actual_inventory: [], enable_live_inventory: [], incentive_percentage_slabs: [], incentive_gst_slabs: [], booking_sources: [], incentive_calculation: [], disable_project: [:walk_ins, :bookings, :invoicing]
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
