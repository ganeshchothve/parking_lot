class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include CrmIntegration

  field :name, type: String
  field :developer_name, type: String
  field :subtype,type: String
  field :advantages, type: Array, default: []
  field :amenities, type: Hash, default: {}
  field :description, type: String
  field :lat, type: String
  field :lng, type: String
  field :sales_pitches, type: Array, default: []
  field :possession, type: Date
  field :is_active,type: Boolean, default: true
  field :is_whitelabelled, type: Boolean, default: false
  field :whitelabel_name, type: String
  field :owner_ids,type: Array,default: []

  #new fields for inventory module
  field :construction_status, type: String  # na,plinth, excavation, 3th floor, 5th floor, 8th floor etc
  field :available_for_transaction, type: String #sell, lease, either
  field :launched_on, type: Date
  field :expected_completion, type: Date
  field :total_buildings, type: Integer, default: 1
  field :type, type: String, default: "residential" #commercial / residential / either
  field :commencement_certificate, type: Boolean
  field :approved_banks, type: Array
  field :suitable_for, type: String # IT/ manufacturing / investors
  field :parking, type: Array #na, closed garage, stilt, podium, open
  field :association_type, type: String
  field :security, type: Array
  field :fire_fighting, type: Boolean
  field :comments,type: String
  field :usp,type: Array,default: []
  field :external_report,type: String
  field :vastu,type: String
  field :loading,type: Float
  field :lock_in_period,type: String
  field :micro_market, type: String
  field :specifications,type: Hash ,default: {}
  field :approval,type: String

  # newly added fields to store data from json
  field :selldo_id, type: String
  field :client_id, type: String
  field :developer_id, type: String
  field :project_pre_sale_ids, type: Array,default: []
  field :project_sale_ids, type: Array,default: []
  field :images, type: Array,default: []
  field :administration, type: String
  field :locality, type: String
  field :project_segment, type: String
  field :project_size, type: String
  field :project_status, type: String
  field :zone, type: String
  field :pitch, type: String
  field :promoted, type: String
  field :total_units, type: Integer
  field :apartment_size, type: String
  field :sync_data, type: Boolean
  field :area_price_data, type: Array, default: []
  field :hide_cost_on_portal, type: String, default: "no"
  field :dedicated_project_phone, type: String
  field :city, type: String
  field :price_type_on_portal, type: String
  field :video, type: String
  field :secondary_developer_ids, type: Array, default: []
  field :secondary_developer_names, type: Array, default: []
  field :foyer_link, type: String
  field :rera_registration_no, type: String


  ##
  # Copied from client for multi project
  #
  field :registration_name, type: String
  field :cin_number, type: String
  field :website_link, type: String
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
  field :cp_disclaimer, type: String
  field :disclaimer, type: String
  field :support_number, type: String
  field :support_email, type: String
  field :channel_partner_support_number, type: String
  field :channel_partner_support_email, type: String
  field :cancellation_amount, type: Float
  field :area_unit, type: String, default: "sqft"
  field :enable_actual_inventory, type: Array, default: []
  field :enable_live_inventory, type: Array, default: []
  field :blocking_amount, type: Integer, default: 30000
  field :blocking_days, type: Integer, default: 10
  field :holding_minutes, type: Integer, default: 15
  field :terms_and_conditions, type: String
  field :ga_code, type: String
  field :gtm_tag, type: String

  field :enable_daily_reports, type: Hash, default: {"payments_report": false}

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
  mount_uploader :brochure, DocUploader

  has_many :project_units
  has_many :schemes
  has_many :project_towers
  has_one :address, as: :addressable
  belongs_to :booking_portal_client, class_name: 'Client'
  has_many :templates
  has_many :sms_templates, class_name: 'Template::SmsTemplate'
  has_many :email_templates, class_name: 'Template::EmailTemplate'
  has_many :ui_templates, class_name: 'Template::UITemplate'
  has_many :emails, class_name: 'Email'
  has_many :smses, class_name: 'Sms'
  has_many :whatsapps, class_name: 'Whatsapp'
  has_many :assets, as: :assetable

  validates :name, :rera_registration_no, presence: true
  validates :enable_actual_inventory, array: { inclusion: {allow_blank: true, in: (User::ADMIN_ROLES + User::BUYER_ROLES) } }
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true

  accepts_nested_attributes_for :address, allow_destroy: true #, :brochure_templates, :price_quote_templates, :images
  index(client_id:1)

  default_scope -> { where(is_active: true)}

  def unit_configurations
    UnitConfiguration.where(data_attributes: {"$elemMatch" => {"n" => "project_id", "v" => self.selldo_id}})
  end

  def compute_area_price
    self.area_price_data = []
    configs = self.unit_configurations  #.select{|x| x.bedrooms > 0}
    if configs.size > 0
      configs.sort_by{|u| [ u.bedrooms ? 0 : 1,u.bedrooms || 0]}.group_by(&:bedrooms).each do |k,v|
        hash = {"name" => k.to_s}
        hash["min_area"] = v.min_by{|obj| obj.saleable }.saleable.round
        hash["max_area"] = v.max_by{|obj| obj.saleable }.saleable.round
        hash["min_price"]= v.min_by{|obj| obj.display_price.values[0].to_i }.display_price.values[0].to_i
        hash["max_price"] = v.max_by{|obj| obj.display_price.values[0].to_i }.display_price.values[0].to_i
        self.area_price_data << hash
      end
    end
  end

  def default_scheme
    Scheme.where(project_id: self.id, default: true).first
  end

  def enable_actual_inventory?(user)
    if user.present?
      enable_actual_inventory.include?(user.role)
    else
      false
    end
  end
end
