class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :selldo_api_key, type: String
  field :selldo_default_srd, type: String
  field :cp_srd, type: String
  field :sfdc_enabled?, type: Boolean
  field :helpdesk_number, type: String
  field :helpdesk_email, type: String
  field :notification_email, type: String
  field :domains, type: Array, default: []
  field :booking_portal_domains, type: Array, default: []
  field :registration_name, type: String
  field :website_link, type: String
  field :cp_disclaimer, type: String
  field :support_number, type: String
  field :support_email, type: String
  field :channel_partner_support_number, type: String
  field :ccavenue_credentials, type: Hash # merchantid, accesscode, working_key

  mount_uploader :logo, DocUploader

  has_many :users, class_name: 'User', inverse_of: 'booking_portal_client'
  has_many :project_units
  has_many :projects
  has_one :address, as: :addressable
end


# Client.create(name: "Amanora", notification_email: "no-reply@amanora.com", domains: ["amanora.com"], booking_portal_domains: ["booking.amanora.com"])
