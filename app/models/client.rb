class Client
  include Mongoid::Document
  include Mongoid::Timestamps

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
  field :enable_actual_inventory, type: Boolean, default: false
  field :enable_channel_partners, type: Boolean, default: false
  field :enable_discounts, type: Boolean, default: false
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
  has_many :sms_templates, class_name: 'SmsTemplate'
  has_many :email_templates, class_name: 'Template::EmailTemplate'
  has_many :smses, class_name: 'Sms'

  has_many :assets, as: :assetable
  has_many :emails, class_name: 'Email', inverse_of: :booking_portal_client
  has_one :gallery
  has_many :discounts, class_name: "Discount"

  validates :name, :allowed_bookings_per_user, :selldo_client_id, :selldo_form_id, :selldo_channel_partner_form_id, :selldo_gre_form_id, :helpdesk_email, :helpdesk_number, :notification_email, :sender_email, :email_domains, :booking_portal_domains, :registration_name, :website_link, :support_email, :support_number, :payment_gateway, :cin_number, :mailgun_private_api_key, :mailgun_email_domain, :sms_provider_username, :sms_provider_password, :sms_mask, presence: true

  validates :preferred_login, inclusion: {in: Proc.new{ Client.available_preferred_logins.collect{|x| x[:id]} } }
  validates :payment_gateway, inclusion: {in: Proc.new{ Client.available_payment_gateways.collect{|x| x[:id]} } }, allow_blank: true
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true

  accepts_nested_attributes_for :address

  def self.available_preferred_logins
    [
      {id: 'phone', text: 'Phone Based'},
      {id: 'email', text: 'Email Based'}
    ]
  end

  def self.available_payment_gateways
    [
      {id: "Razorpay", text: "Razorpay Payment Gateway"}
    ]
  end

  def sms_enabled?
    self.enable_communication["sms"]
  end

  def email_enabled?
    self.enable_communication["email"]
  end
end

=begin
c = Client.new
c.name = "Amura"
c.selldo_client_id = "531de108a7a03997c3000002"
c.selldo_form_id = "5abba073923d4a567f880952"
c.selldo_gre_form_id = "5abba073923d4a567f880952"
c.selldo_channel_partner_form_id = "5abba073923d4a567f880952"
c.selldo_api_key = "bcdd92826cf283603527bd6d832d16c4"
c.selldo_default_srd = "5a72c7a67c0dac7e854aca9e"
c.selldo_cp_srd = "5a72c7a67c0dac7e854aca9e"
c.helpdesk_number = "9922410908"
c.helpdesk_email = "supriya@amuratech.com"
c.ga_code = ""
c.gtm_tag = ""
c.notification_email = "supriya@amuratech.com"
c.email_domains = ["amuratech.com"]
c.booking_portal_domains = ["bookingportal.withamura.com"]
c.registration_name = "Amura Marketing Technologies Pvt. Ltd."
c.website_link = "www.amuratech.com"
c.cp_disclaimer = "CP Disclaimer"
c.disclaimer = "End User Disclaimer"
c.support_number = "9922410908"
c.support_email = "supriya@amuratech.com"
c.sender_email = "supriya@amuratech.com"
c.channel_partner_support_number = "9922410908"
c.channel_partner_support_email = "supriya@amuratech.com"
c.cancellation_amount = 5000
c.area_unit = "psqft."
c.preferred_login = "phone"
c.sms_provider_username = "amuramarketing"
c.sms_provider_password = "aJ_Z-1j4"
c.enable_actual_inventory = false
c.enable_channel_partners = false
c.enable_discounts = false
c.enable_company_users = true
c.remote_logo_url = "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png"
c.allowed_bookings_per_user = 5
c.save

p = Project.new
p.name = "Amura Towers"
p.remote_logo_url = "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png"
p.rera_registration_no = "RERA-AMURA-123"
p.booking_portal_client = Client.first
p.save

u = User.new(first_name: "Ketan", last_name: "Sabnis", role: "admin", booking_portal_client: Client.first, email: "ketan@amuratech.com", phone: "+919552523663")
u.confirm
u.skip_confirmation_notification!
u.save
=end
