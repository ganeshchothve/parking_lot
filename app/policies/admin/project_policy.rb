class Admin::ProjectPolicy < ProjectPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin].include?(user.role)
  end

  def asset_create?
    update?
  end

  def index?
    update?
  end

  def create?
    update?
  end

  def ds?
    current_client.enable_actual_inventory?(user)
  end

  def permitted_attributes(params = {})
    attributes = [:name, :rera_registration_no, :selldo_client_id, :selldo_form_id, :allowed_bookings_per_user, :selldo_gre_form_id, :selldo_channel_partner_form_id, :selldo_api_key, :selldo_default_srd, :selldo_cp_srd, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag, :notification_email, :notification_numbers, :sender_email, :registration_name, :cin_number, :website_link, :cp_disclaimer, :disclaimer, :support_number, :support_email, :channel_partner_support_number, :channel_partner_support_email, :cancellation_amount, :area_unit, :blocking_amount, :blocking_days, :holding_minutes, :terms_and_conditions, :logo, :mobile_logo, :brochure, address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, third_party_references_attributes: [:id, :reference_id], email_domains: [], booking_portal_domains: [], enable_actual_inventory: [], enable_live_inventory: []]
    attributes.uniq
  end
end
