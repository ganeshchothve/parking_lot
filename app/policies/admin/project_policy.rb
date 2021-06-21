class Admin::ProjectPolicy < ProjectPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin admin].include?(user.role)
  end

  def asset_create?
    %w[superadmin admin].include?(user.role)
  end

  def asset_update?
    asset_create?
  end

  def index?
    !user.buyer? && (current_client.enable_actual_inventory?(user) || enable_incentive_module?(user))
  end

  def show?
    index?
  end

  def create?
    update?
  end

  def collaterals?
    true
  end

  def ds?
    current_client.enable_actual_inventory?(user)
  end

  def permitted_attributes(params = {})
    attributes = [:name, :developer_id, :project_type, :category, :project_segment, :micro_market, :city, :possession, :launched_on, :our_expected_possession, :total_buildings, :total_units, :description, :advantages, :video_link, :registration_name, :rera_registration_no, :gst_number, :cin_number, :website_link,
      :project_size, :is_active, :total_buildings, :logo, :mobile_cover_photo, :cover_photo, :mobile_logo, approved_banks: [], configurations: [], amenities: [], address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    if user.role?(:superadmin)
      attributes += [
        :selldo_client_id, :selldo_id, :selldo_default_search_list_id, :selldo_form_id, :selldo_gre_form_id,
        :selldo_channel_partner_form_id, :selldo_api_key, :selldo_default_srd, :selldo_cp_srd,
        :allowed_bookings_per_user, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag,
        :notification_email, :notification_numbers, :sender_email, :area_unit,
        :support_number, :support_email, :channel_partner_support_number, :channel_partner_support_email, :cancellation_amount, :blocking_amount,
        :blocking_days, :holding_minutes, :terms_and_conditions, :email_header, :email_footer, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes,
        email_domains: [], booking_portal_domains: [], enable_actual_inventory: [], enable_live_inventory: []
      ]
    end
    attributes.uniq
  end
end
