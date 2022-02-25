class Client
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  PAYMENT_GATEWAYS = %w(Razorpay CCAvenue)
  # Add different types of documents which are uploaded on client
  DOCUMENT_TYPES = %w[document offer login_page_image].freeze
  PUBLIC_DOCUMENT_TYPES = []
  INCENTIVE_CALCULATION = ["manual", "calculated"]

  field :name, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :selldo_channel_partner_form_id, type: String
  field :selldo_gre_form_id, type: String
  field :selldo_api_key, type: String
  field :selldo_api_secret, type: String
  field :selldo_default_srd, type: String
  field :selldo_cp_srd, type: String
  field :helpdesk_number, type: String
  field :helpdesk_email, type: String
  field :notification_email, type: String
  field :notification_numbers, type: String
  field :allowed_bookings_per_user, type: Integer, default: 3
  field :sender_email, type: String
  field :general_user_request_categories, type: Array, default: []
  field :email_domains, type: Array, default: []
  field :booking_portal_domains, type: Array, default: []
  field :registration_name, type: String
  field :cin_number, type: String
  field :website_link, type: String
  field :cp_disclaimer, type: String
  field :disclaimer, type: String
  field :support_number, type: String
  field :support_email, type: String
  field :channel_partner_support_number, type: String
  field :channel_partner_support_email, type: String
  field :erp, type: Hash, default: {} # name, access_token, instance_url, client_id, username, password, client_secret
  field :cancellation_amount, type: Float
  field :area_unit, type: String, default: "sqft"
  field :preferred_login, type: String, default: "phone"
  field :mixpanel_token, type: String
  field :sms_provider_username, type: String
  field :sms_provider_password, type: String
  field :sms_provider_telemarketer_id, type: String
  field :whatsapp_api_key, type: String
  field :whatsapp_api_secret, type: String
  field :whatsapp_vendor, type: String, default: 'twilio'
  field :notification_api_key, type: String
  field :notification_vendor, type: String, default: 'firebase'
  field :sms_provider_dlt_entity_id, type: String
  field :sms_mask, type: String, default: "SellDo"
  field :sms_provider, type: String, default: 'sms_just'
  field :mailgun_private_api_key, type: String
  field :mailgun_email_domain, type: String
  field :twilio_auth_token, type: String
  field :twilio_account_sid, type: String
  field :twilio_virtual_number, type: String
  field :enable_actual_inventory, type: Array, default: []
  field :enable_live_inventory, type: Array, default: []
  field :enable_channel_partners, type: Boolean, default: false
  field :enable_direct_payment, type: Boolean, default: false
  field :enable_payment_with_kyc, type: Boolean, default: true
  field :enable_booking_with_kyc, type: Boolean, default: true
  field :incentive_calculation, type: Array, default: ["manual"]
  field :enable_direct_activation_for_cp, type: Boolean, default: false
  field :blocking_amount, type: Integer, default: 30000
  field :blocking_days, type: Integer, default: 10
  field :holding_minutes, type: Integer, default: 15
  field :payment_gateway, type: String, default: 'Razorpay'
  field :enable_company_users, type: Boolean
  field :terms_and_conditions, type: String
  field :faqs, type: String
  field :rera, type: String
  field :tds_process, type: String
  field :ga_code, type: String
  field :gtm_tag, type: String
  field :enable_communication, type: Hash, default: { 'email': true, 'sms': true, 'whatsapp': false, 'notification': false }
  field :allow_multiple_bookings_per_user_kyc, type: Boolean, default: true
  field :enable_referral_bonus, type: Boolean, default: false
  field :roles_taking_registrations, type: Array, default: %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner cp_owner]
  field :lead_blocking_days, type: Integer
  field :invoice_approval_tat, type: Integer, default: 2

  field :external_api_integration, type: Boolean, default: false
  field :enable_daily_reports, type: Hash, default: {"payments_report": false}
  field :enable_incentive_module, type: Array, default: []
  field :partner_regions, type: Array, default: ['Pune West', 'Pune East', 'Others']
  #
  # This setting will decide how same lead can be added through different channel partners,
  # Enabled: If channel_partner tries to add a lead which is already present in the system & tagged to different channel_partner, then system will check if the lead is confirmed or not, if yes, it won't allow the current channel_partner to add it again & trigger an email to admin saying current channel_partner tried to add an existing lead.
  # Disabled: If channel_partner tries to add an already present lead under diff. channel_partner, then system will not allow current channel_partner to add that lead again regardless of its confirmation status & trigger a notification email to admin informing that current channel_partner tried to add existing lead.
  field :enable_lead_conflicts, type: Boolean, default: false
  # required for sell.do links of sitevisit, followup & add task on user to work.
  field :selldo_default_search_list_id, type: String
  field :powered_by_link, type: String
  field :launchpad_portal, type: Boolean, default: false
  field :mask_lead_data_for_roles, type: Array, default: %w(admin superadmin cp cp_admin dev_sourcing_manager)
  field :incentive_gst_slabs, type: Array, default: [5, 12, 18]

  field :email_header, type: String, default: '<div class="container">
    <img class="mx-auto mt-3 mb-3" maxheight="65" src="<%= current_client.logo.url %>" />
    <div class="mt-3"></div>'
  field :email_footer, type: String, default: '<div class="mt-3"></div>
    <div class="card mb-3">
      <div class="card-body">
        Thanks,<br/>
        <%= current_client.name %>
      </div>
    </div>
    <div style="font-size: 12px;">
      If you have any queries you can reach us at <%= current_client.support_number %> or write to us at <%= current_client.support_email %>. Please click <a href="<%= current_client.website_link %>">here</a> to visit our website.
    </div>
    <hr/>
    <div class="text-muted text-center" style="font-size: 12px;">
      © <%= Date.today.year %> <%= current_client.name %>. All Rights Reserved.
    </div>
    <% if current_client.address.present? %>
      <div class="text-muted text-center" style="font-size: 12px;">
        <%= current_client.address.to_sentence %>
      </div>
    <% end %>
    <div class="mt-3"></div>
  </div>'

  mount_uploader :logo, PublicAssetUploader
  mount_uploader :mobile_logo, PublicAssetUploader
  mount_uploader :background_image, DocUploader


  enable_audit track: ["update"]

  has_many :users, class_name: 'User', inverse_of: 'booking_portal_client'
  has_many :project_units
  has_many :projects
  has_one :address, as: :addressable
  has_many :templates
  has_many :sms_templates, class_name: 'Template::SmsTemplate'
  has_many :email_templates, class_name: 'Template::EmailTemplate'
  has_many :ui_templates, class_name: 'Template::UITemplate'
  has_many :notification_templates, class_name: 'Template::NotificationTemplate'
  has_many :smses, class_name: 'Sms'
  has_many :whatsapps, class_name: 'Whatsapp'
  has_many :push_notifications, class_name: 'PushNotification'
  has_many :assets, as: :assetable
  has_many :public_assets, as: :public_assetable
  has_many :emails, class_name: 'Email', inverse_of: :booking_portal_client
  has_many :schemes
  has_many :bulk_upload_reports
  has_one :gallery
  has_one :external_inventory_view_config, inverse_of: :booking_portal_client
  has_one :document_sign
  embeds_many :checklists, cascade_callbacks: true

  validates :name, :allowed_bookings_per_user, :helpdesk_email, :helpdesk_number, :notification_email, :notification_numbers, :sender_email, :email_domains, :booking_portal_domains, :registration_name, :website_link, :support_email, :support_number, :payment_gateway, :cin_number, :mailgun_private_api_key, :mailgun_email_domain, :sms_provider_username, :sms_provider_password, :sms_mask, presence: true
  validates :enable_actual_inventory, array: { inclusion: {allow_blank: true, in: (User::ADMIN_ROLES + User::BUYER_ROLES) } }
  validates :preferred_login, inclusion: {in: Proc.new{ Client.available_preferred_logins.collect{|x| x[:id]} } }
  validates :payment_gateway, inclusion: {in: Proc.new{ Client::PAYMENT_GATEWAYS } }, allow_blank: true
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true
  validates :whatsapp_api_key, :whatsapp_api_secret, presence: true, if: :whatsapp_enabled?
  validates :notification_api_key, presence: true, if: :notification_enabled?
  accepts_nested_attributes_for :address, :external_inventory_view_config, :checklists

  def self.available_preferred_logins
    [
      {id: 'phone', text: 'Phone Based'},
      {id: 'email', text: 'Email Based'}
    ]
  end

  def sms_enabled?
    self.enable_communication["sms"]
  end

  def email_enabled?
    self.enable_communication["email"]
  end

  def whatsapp_enabled?
    self.enable_communication['whatsapp']
  end

  def notification_enabled?
    self.enable_communication['notification']
  end

  def enable_actual_inventory?(user)
    if user.present?
      out = enable_actual_inventory.include?(user.role)
      out && user.active_channel_partner?
    else
      false
    end
  end

  def incentive_calculation_type?(_type)
    if _type.present?
      incentive_calculation.include?(_type)
    else
      false
    end
  end

  def enable_incentive_module?(user)
    if user.present?
      out = enable_incentive_module.include?(user.role)
      out && (user.active_channel_partner? || user.role?('billing_team'))
    else
      false
    end
  end

  def self.selldo_api_clients
    ENV_CONFIG.dig(:selldo, :api_clients) || {}
  end
end
