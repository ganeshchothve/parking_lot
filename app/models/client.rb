class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :cp_srd, type: String
  field :sfdc_enabled?, type: Boolean
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
  field :payment_gateway_credentials, type: Hash, default: {} # merchantid, accesscode, working_key
  field :erp, type: Hash, default: {} # name, access_token, instance_url, client_id, username, password, client_secret
  field :area_unit, type: String, default: "sqft"

  mount_uploader :logo, DocUploader

  has_many :users, class_name: 'User', inverse_of: 'booking_portal_client'
  has_many :project_units
  has_many :projects
  has_one :address, as: :addressable

  validate :name, :selldo_client_id, :selldo_form_id, :helpdesk_email, :helpdesk_number, :notification_email, :email_domains, :booking_portal_domains, :registration_name, :website_link, :support_email, :support_number
end


# Client.create(name: "Amanora", notification_email: "no-reply@amanora.com", email_domains: ["amanora.com"], booking_portal_domains: ["booking.amanora.com"])
