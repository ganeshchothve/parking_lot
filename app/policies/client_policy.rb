class ClientPolicy < ApplicationPolicy
  # def new? def create? def edit? def update? from ApplicationPolicy

  def allow_marketplace_access?
    !marketplace_client? || (current_client.kylas_api_key.present? && current_client.errors.blank?)
  end

  def permitted_attributes params={}
    case record.industry
    when 'real_estate'
      attrs = [
        :basic, :bookings, :contacts, :integrations, :pages, :logos,
        :name, :selldo_client_id, :selldo_form_id,
        :allowed_bookings_per_user, :selldo_gre_form_id, :selldo_channel_partner_form_id, :selldo_api_key,
        :selldo_api_secret, :selldo_default_srd, :selldo_cp_srd, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag,
        :notification_email, :notification_numbers, :sender_email, :registration_name, :cin_number, :website_link,
        :cp_disclaimer, :disclaimer, :support_number, :support_email, :channel_partner_support_number,
        :channel_partner_support_email, :cancellation_amount, :area_unit, :mixpanel_token, :enable_payment,
        :blocking_amount, :blocking_amount_editable, :enable_booking_with_kyc,
        :blocking_days, :holding_minutes, :payment_gateway, :email_header, :email_footer,
        :faqs, :rera, :tds_process, :logo, :mobile_logo, :background_image, :enable_customer_registration, :lead_blocking_days,
        :enable_direct_activation_for_cp, :external_api_integration, :powered_by_link,
        external_inventory_view_config_attributes: ExternalInventoryViewConfigPolicy.new(user, ExternalInventoryViewConfig.new).permitted_attributes,
        address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes,
        checklists_attributes: ChecklistPolicy.new(user, Checklist.new).permitted_attributes,
        regions_attributes: RegionPolicy.new(user, Region.new).permitted_attributes,
        email_domains: [], booking_portal_domains: [], enable_actual_inventory: [], enable_live_inventory: [],
        enable_incentive_module: [], incentive_calculation: [], incentive_gst_slabs: []
      ]
    when 'generic'
      attrs = [
        :basic, :contacts, :logos,
        :name, :logo, :mobile_logo, :cin_number,
        address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes,
      ]
    end
    if user.role.in?(%w(superadmin))
      attrs += [:enable_channel_partners, :enable_leads, :enable_site_visit, :allow_lead_duplication, :enable_lead_conflicts, :enable_floor_band]
    end
    attrs += [:sms_provider_dlt_entity_id, :notification_api_key, :sms_provider_telemarketer_id, :sms_provider, :sms_provider_username, :sms_provider_password, :whatsapp_api_key, :whatsapp_api_secret,
      :mailgun_private_api_key, :mailgun_email_domain, :sms_mask, :preferred_login]
    attrs += [enable_communication: [:email, :sms, :whatsapp, :notification]]
    attrs.uniq
  end
end
