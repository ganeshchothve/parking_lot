class Client
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :name, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :selldo_channel_partner_form_id, type: String
  field :selldo_gre_form_id, type: String
  field :selldo_api_key, type: String
  field :selldo_default_srd, type: String
  field :selldo_cp_srd, type: String
  field :helpdesk_number, type: String
  field :helpdesk_email, type: String
  field :notification_email, type: String
  field :notification_numbers, type: String
  field :allowed_bookings_per_user, type: Integer, default: 3
  field :sender_email, type: String
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
  field :sms_mask, type: String, default: "SellDo"
  field :mailgun_private_api_key, type: String
  field :mailgun_email_domain, type: String
  field :enable_actual_inventory, type: Array, default: []
  field :enable_channel_partners, type: Boolean, default: false
  field :enable_direct_payment, type: Boolean, default: false
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
  field :enable_communication, type: Hash, default: {"email": true, "sms": true}
  field :allow_multiple_bookings_per_user_kyc, type: Boolean, default: true
  field :enable_referral_bonus, type: Boolean, default: false

  field :email_header, type: String, default: '<div class="container">
    <img class="mx-auto mt-3 mb-3" maxheight="65" src="<%= current_client.logo.url %>" />
    <div class="mt-3"></div>'
  field :email_footer, type: String, default: '<div class="mt-3"></div>
    <div class="card mb-3">
      <div class="card-body">
        Thanks,<br/>
        <%= current_project.name %>
      </div>
    </div>
    <div style="font-size: 12px;">
      If you have any queries you can reach us at <%= current_client.support_number %> or write to us at <%= current_client.support_email %>. Please click <a href="<%= current_client.website_link %>">here</a> to visit our website.
    </div>
    <hr/>
    <div class="text-muted text-center" style="font-size: 12px;">
      © <%= Date.today.year %> <%= current_client.name %>. All Rights Reserved. | MAHARERA ID: <%= current_project.rera_registration_no %>
    </div>
    <% if current_client.address.present? %>
      <div class="text-muted text-center" style="font-size: 12px;">
        <%= current_client.address.to_sentence %>
      </div>
    <% end %>
    <div class="mt-3"></div>
  </div>'

  mount_uploader :logo, DocUploader
  mount_uploader :mobile_logo, DocUploader
  mount_uploader :background_image, DocUploader

  enable_audit track: ["update"]

  has_many :users, class_name: 'User', inverse_of: 'booking_portal_client'
  has_many :project_units
  has_many :projects
  has_one :address, as: :addressable
  has_many :templates
  has_many :sms_templates, class_name: 'Template::SmsTemplate'
  has_many :email_templates, class_name: 'Template::EmailTemplate'
  has_many :smses, class_name: 'Sms'
  has_many :assets, as: :assetable
  has_many :emails, class_name: 'Email', inverse_of: :booking_portal_client
  has_many :schemes
  has_one :gallery
  has_one :external_inventory_view_config, inverse_of: :booking_portal_client

  validates :name, :allowed_bookings_per_user, :helpdesk_email, :helpdesk_number, :notification_email, :notification_numbers, :sender_email, :email_domains, :booking_portal_domains, :registration_name, :website_link, :support_email, :support_number, :payment_gateway, :cin_number, :mailgun_private_api_key, :mailgun_email_domain, :sms_provider_username, :sms_provider_password, :sms_mask, presence: true
  validates :enable_actual_inventory, array: {inclusion: {allow_blank: true, in: Proc.new{ |client| User.available_roles(client).collect{|x| x[:id]} } }}
  validates :preferred_login, inclusion: {in: Proc.new{ Client.available_preferred_logins.collect{|x| x[:id]} } }
  validates :payment_gateway, inclusion: {in: Proc.new{ Client.available_payment_gateways.collect{|x| x[:id]} } }, allow_blank: true
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true

  accepts_nested_attributes_for :address, :external_inventory_view_config

  def self.available_preferred_logins
    [
      {id: 'phone', text: 'Phone Based'},
      {id: 'email', text: 'Email Based'}
    ]
  end

  def self.available_payment_gateways
    [
      {id: "Razorpay", text: "Razorpay Payment Gateway"},
      {id: "CCAvenue", text: "CCAvenue Payment Gateway"}
    ]
  end

  def sms_enabled?
    self.enable_communication["sms"]
  end

  def email_enabled?
    self.enable_communication["email"]
  end

  def enable_actual_inventory?(user)
    if user.present?
      enable_actual_inventory.include?(user.role)
    else
      false
    end
  end
end