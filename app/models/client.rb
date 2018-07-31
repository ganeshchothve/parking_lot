class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :selldo_api_key, type: String
  field :selldo_default_srd, type: String
  field :cp_srd, type: String
  field :sfdc_enabled, type: Boolean
  field :helpdesk_number, type: String
  field :helpdesk_email, type: String
  field :notification_email, type: String
  field :email_domains, type: Array, default: []
  field :booking_portal_domains, type: Array, default: []
  field :registration_name, type: String
  field :website_link, type: String
  field :cp_disclaimer, type: String
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
  field :enable_actual_inventory, type: Boolean, default: false
  field :enable_channel_partners, type: Boolean, default: false
  field :blocking_amount, type: Integer, default: 30000
  field :blocking_days, type: Integer, default: 10
  field :holding_minutes, type: Integer, default: 15

  mount_uploader :logo, DocUploader

  has_many :users, class_name: 'User', inverse_of: 'booking_portal_client'
  has_many :project_units
  has_many :projects
  has_one :address, as: :addressable

  validate :name, :selldo_client_id, :selldo_form_id, :helpdesk_email, :helpdesk_number, :notification_email, :email_domains, :booking_portal_domains, :registration_name, :website_link, :support_email, :support_number

  def self.available_preferred_logins
    [
      {id: 'phone', text: 'Phone Based'},
      {id: 'email', text: 'Email Based'}
    ]
  end
  validates :preferred_login, inclusion: {in: Proc.new{ Client.available_preferred_logins.collect{|x| x[:id]} } }
end

=begin
c = Client.new
c.name = "Amura"
c.selldo_client_id = "531de108a7a03997c3000002"
c.selldo_form_id = "5abba073923d4a567f880952"
c.selldo_api_key = "bcdd92826cf283603527bd6d832d16c4"
c.selldo_default_srd = "5a72c7a67c0dac7e854aca9e"
c.cp_srd = "5a72c7a67c0dac7e854aca9e"
c.helpdesk_number = "9922410908"
c.helpdesk_email = "supriya@amuratech.com"
c.notification_email = "supriya@amuratech.com"
c.email_domains = ["amuratech.com"]
c.booking_portal_domains = ["bookingportal.withamura.com"]
c.registration_name = "Amura Marketing Technologies Pvt. Ltd."
c.website_link = "www.amuratech.com"
c.cp_disclaimer = "CP Disclaimer"
c.support_number = "9922410908"
c.support_email = "supriya@amuratech.com"
c.channel_partner_support_number = "9922410908"
c.channel_partner_support_email = "supriya@amuratech.com"
c.cancellation_amount = 5000
c.area_unit = "psqft."
c.preferred_login = "phone"
c.sms_provider_username = "amuramarketing"
c.sms_provider_password = "aJ_Z-1j4"
c.enable_actual_inventory = false
c.enable_channel_partners = false
c.remote_logo_url = "https://image4.owler.com/logo/amura_owler_20160227_194208_large.png"
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
