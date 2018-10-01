class ClientPolicy < ApplicationPolicy
  def edit?
    user.role == "superadmin"
  end

  def new?
    false
  end

  def create?
    false
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    [:name, :selldo_client_id, :selldo_form_id, :allowed_bookings_per_user, :selldo_gre_form_id, :selldo_channel_partner_form_id, :selldo_api_key, :selldo_default_srd, :selldo_cp_srd, :helpdesk_number, :helpdesk_email, :ga_code, :gtm_tag, :notification_email, :notification_numbers, :sender_email, :registration_name, :cin_number, :website_link, :cp_disclaimer, :disclaimer, :support_number, :support_email, :channel_partner_support_number, :channel_partner_support_email, :cancellation_amount, :area_unit, :preferred_login, :mixpanel_token, :sms_provider_username, :sms_provider_password, :mailgun_private_api_key, :mailgun_email_domain, :sms_mask, :enable_channel_partners, :enable_direct_payment, :blocking_amount, :blocking_amount_editable, :blocking_days, :holding_minutes, :payment_gateway, :enable_company_users, :terms_and_conditions, :faqs, :rera, :tds_process, :logo, :mobile_logo, :background_image, :allow_multiple_bookings_per_user_kyc, enable_communication: [:email, :sms], external_inventory_view_config_attributes: ExternalInventoryViewConfigPolicy.new(user, ExternalInventoryViewConfig.new).permitted_attributes, address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, email_domains: [], booking_portal_domains: [], enable_actual_inventory: []]
  end
end
