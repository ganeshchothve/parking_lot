class ClientPolicy < ApplicationPolicy
  # def new? def create? def edit? def update? from ApplicationPolicy

  def permitted_attributes params={}
    attrs = [
      :sms_provider_dlt_entity_id, :notification_api_key, :sms_provider_telemarketer_id, :name, :selldo_client_id, :selldo_form_id,
      :allowed_bookings_per_user, :selldo_gre_form_id, :selldo_channel_partner_form_id, :selldo_api_key,
      :selldo_api_secret, :selldo_default_srd, :selldo_cp_srd, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag,
      :notification_email, :notification_numbers, :sender_email, :registration_name, :cin_number, :website_link,
      :cp_disclaimer, :disclaimer, :support_number, :support_email, :channel_partner_support_number,
      :channel_partner_support_email, :cancellation_amount, :area_unit, :preferred_login, :mixpanel_token,
      :sms_provider, :sms_provider_username, :sms_provider_password, :whatsapp_api_key, :whatsapp_api_secret,
      :mailgun_private_api_key, :mailgun_email_domain, :sms_mask, :enable_direct_payment,
      :blocking_amount, :blocking_amount_editable, :enable_referral_bonus, :enable_payment_with_kyc, :enable_booking_with_kyc,
      :blocking_days, :holding_minutes, :payment_gateway, :enable_company_users, :email_header, :email_footer,
      :terms_and_conditions, :faqs, :rera, :tds_process, :logo, :mobile_logo, :background_image,
      :allow_multiple_bookings_per_user_kyc, :enable_lead_conflicts, :lead_blocking_days,
      :enable_direct_activation_for_cp, :external_api_integration, :invoice_approval_tat, :powered_by_link, :launchpad_portal, :tl_dashboard_refresh_timer, :payment_link_validity_hours,
      enable_communication: [:email, :sms, :whatsapp, :notification],
      external_inventory_view_config_attributes: ExternalInventoryViewConfigPolicy.new(user, ExternalInventoryViewConfig.new).permitted_attributes,
      address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes,
      checklists_attributes: ChecklistPolicy.new(user, Checklist.new).permitted_attributes,
      regions_attributes: RegionPolicy.new(user, Region.new).permitted_attributes,
      email_domains: [], booking_portal_domains: [], enable_actual_inventory: [], enable_live_inventory: [],
      enable_incentive_module: [], incentive_calculation: [], incentive_gst_slabs: []
    ]
    if user.role.in?(%w(superadmin))
      if record.kylas_tenant_id.present?
        attrs += [:enable_channel_partners, :enable_leads, :enable_site_visit]
      else
        attrs += [:enable_vis, :enable_channel_partners, :enable_leads, :enable_site_visit]
      end
    end
    attrs.uniq
  end
end
