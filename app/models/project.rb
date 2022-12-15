class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include ArrayBlankRejectable
  include CrmIntegration
  include ApplicationHelper
  extend ApplicationHelper
  include ProjectOnboardingOnSelldo
  extend FilterByCriteria
  extend DocumentsConcern

  # Add different types of documents which are uploaded on client
  DOCUMENT_TYPES = %w[document brochure certificate unit_selection_filter_image sales_presentation images developer_logo advertise].freeze
  CATEGORIES = %w( pre_launch launch ongoing completed)
  SEGMENTS = %w( affordable value luxury ultra_luxury )
  PROJECT_TYPES = %w( commercial residential )
  DEFAULT_AMENITIES = %w( swimming_pool table_tennis_court movie_theatre gym auditorium playschool sewage_treatment_plant internal_roads )
  DEFAULT_CONFIGURATIONS = %w( 1RK 1BHK 2BHK 2.5BHK 3BHK 3.5BHK 4BHK 5BHK 6BHK )
  ALLOWED_BANKS = %w( sbi hdfc bob bajaj_finance )

  # filters
  field :name, type: String
  field :developer_name, type: String
  field :developer_rating, type: Integer
  field :category, type: Array, default: []
  field :project_segment, type: Array, default: []
  field :possession, type: Date
  field :latitude, type: String, default: '100'
  field :longitude, type: String, default: '100'
  field :is_active,type: Boolean, default: true
  field :area_price_data, type: Array, default: []
  field :configurations, type: Array, default: []
  field :micro_market, type: String
  field :city, type: String
  field :project_type, type: Array, default: [ "residential" ]
  field :region, type: String
  field :support_name, type: String
  field :support_mail, type: String
  field :support_phone, type: String
  field :payment_enabled, type: Boolean, default: true

  # descriptive fields
  field :description, type: String
  field :advantages, type: String
  field :video_link, type: String

  # attributes
  field :launched_on, type: Date
  field :our_expected_possession, type: Date
  field :total_buildings, type: Integer, default: 1
  field :total_units, type: Integer, default: 1
  field :rera_registration_no, type: String
  field :approved_banks, type: Array, default: []
  field :booking_sources, type: Array, default: []
  field :project_size, type: String
  field :gst_slab_applicable, type: Boolean, default: true
  field :incentive_percentage_slabs, type: Array, default: [5, 12, 18]
  field :incentive_gst_slabs, type: Array, default: [5, 12, 18]
  field :sv_incentive, type: Integer
  field :spot_booking_incentive, type: Integer
  field :pre_reg_incentive_percentage, type: Integer
  field :pre_reg_min_bookings, type: Integer
  field :iris_url, type: String

  # selldo attributes
  field :selldo_id, type: String
  field :selldo_developer_id, type: String
  field :selldo_client_id, type: String
  field :selldo_form_id, type: String
  field :selldo_channel_partner_form_id, type: String
  field :selldo_gre_form_id, type: String
  field :selldo_api_key, type: String
  field :selldo_default_srd, type: String
  field :selldo_default_search_list_id, type: String
  field :selldo_cp_srd, type: String
  field :amenities, type: Array, default: []

  # meta attributes
  field :foyer_link, type: String
  field :registration_name, type: String
  field :cin_number, type: String
  field :website_link, type: String
  field :notification_email, type: String
  field :notification_numbers, type: String
  field :allowed_bookings_per_user, type: Integer, default: 300
  field :sender_email, type: String
  field :email_domains, type: Array, default: []
  field :booking_portal_domains, type: Array, default: []
  field :cp_disclaimer, type: String
  field :disclaimer, type: String
  field :helpdesk_number, type: String
  field :helpdesk_email, type: String
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
  field :consideration_value_help_text, type: String
  field :ga_code, type: String
  field :gtm_tag, type: String
  field :gst_number, type: String
  field :enable_daily_reports, type: Hash, default: {"payments_report": false}
  field :enable_slot_generation, type: Boolean, default: false
  field :embed_map_tag, type: String
  field :usp, type: Array, default: []
  field :hot, type: Boolean, default: false
  field :price_starting_from, type: Integer
  field :price_upto, type: Integer
  field :broker_usp, type: Array, default: []
  field :enable_inventory, type: Boolean, default: false
  field :enable_booking_with_kyc, type: Boolean, default: true
  field :check_sv_availability_in_selldo, type: Boolean, default: false
  field :incentive_calculation, type: Array, default: ["manual"]
  field :disable_project, type: Hash, default: {walk_ins: false, bookings: false, invoicing: false}

  # Kylas fields
  field :kylas_product_id, type: String
  field :kylas_product_value, type: Integer
  # Kylas Custom Fields options values fields
  field :kylas_custom_fields_option_id, type: Hash, default: {}

  field :email_header, type: String, default: '<div class="container">
    <img class="mx-auto mt-3 mb-3" maxheight="65" src="<%= client.logo.url %>" />
    <div class="mt-3"></div>'
  field :email_footer, type: String, default: '<div class="mt-3"></div>
    <div class="card mb-3">
      <div class="card-body">
        Thanks,<br/>
        <%= current_project.name %>
      </div>
    </div>
    <div style="font-size: 12px;">
      If you have any queries you can reach us at <%= current_project.support_number %> or write to us at <%= current_project.support_email %>. Please click <a href="<%= client.website_link %>">here</a> to visit our website.
    </div>
    <hr/>
    <div class="text-muted text-center" style="font-size: 12px;">
      © <%= Date.today.year %> <%= current_project.name %>. All Rights Reserved. | MAHARERA ID: <%= current_project.rera_registration_no %>
    </div>
    <% if client.address.present? %>
      <div class="text-muted text-center" style="font-size: 12px;">
        <%= client.address.to_sentence %>
      </div>
    <% end %>
    <div class="mt-3"></div>
  </div>'  

  mount_uploader :logo, DocUploader
  mount_uploader :mobile_logo, DocUploader
  mount_uploader :cover_photo, DocUploader
  mount_uploader :mobile_cover_photo, DocUploader

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :developer, optional: true
  belongs_to :creator, class_name: 'User'
  has_many :project_units
  has_many :booking_details
  has_many :schemes
  has_many :project_towers
  has_one :address, as: :addressable
  has_many :templates
  has_many :sms_templates, class_name: 'Template::SmsTemplate'
  has_many :email_templates, class_name: 'Template::EmailTemplate'
  has_many :ui_templates, class_name: 'Template::UITemplate'
  has_many :emails, class_name: 'Email'
  has_many :smses, class_name: 'Sms'
  has_many :whatsapps, class_name: 'Whatsapp'
  has_many :assets, as: :assetable
  has_many :notes, as: :notable
  has_many :receipts
  has_many :specifications
  has_many :offers
  has_many :incentive_schemes
  has_many :timeline_updates
  has_and_belongs_to_many :campaigns
  has_many :token_types
  has_many :time_slots
  has_many :unit_configurations
  has_many :videos, as: :videoable
  has_many :nearby_locations
  has_many :invoices

  validates :name, presence: true
  validates :name, uniqueness: {scope: :booking_portal_client_id}, presence: true
  validates_uniqueness_of :rera_registration_no, allow_blank: true
  validates :enable_actual_inventory, array: { inclusion: {allow_blank: true, in: (User::ADMIN_ROLES + User::BUYER_ROLES) } }
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true
  validates :gst_number, uniqueness: { allow_blank: true }
  validates :city, inclusion: { in: proc  { |project| project.booking_portal_client.regions.distinct(:city) } }, allow_blank: true
  validates :region, inclusion: { in: proc { |project| project.booking_portal_client.regions.distinct(:partner_regions).flatten || [] } }, allow_blank: true

  accepts_nested_attributes_for :specifications, :offers, :timeline_updates, :address, :nearby_locations, allow_destroy: true

  default_scope { order(hot: :desc, created_at: :desc) }

  scope :filter_by__id, ->(_id) { all.in(_id: (_id.is_a?(Array) ? _id : [_id])) }
  scope :filter_by_category, ->(category) {category.is_a?(Array) ? where(category: {'$in': category}) : where(category: category) }
  scope :filter_by_project_segment, ->(project_segment) {project_segment.is_a?(Array) ? where(project_segment: {'$in': project_segment} ) : where(project_segment: project_segment) }
  scope :filter_by_configurations, ->(configurations) { configurations.is_a?(Array) ? where(configurations: {'$in': configurations} ) : where(configurations: configurations) }
  scope :filter_by_city, ->(city) { where(city: city) }
  scope :filter_by_project_type, ->(project_type) { where(project_type: project_type) }
  scope :filter_by_micro_market, ->(micro_market) { where(micro_market: micro_market) }
  scope :filter_by_possession, ->(date) { start_date, end_date = date.split(' - '); where(possession: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_hot, ->(hot) { where(hot: hot.eql?("true")) }
  scope :filter_by_user_interested_projects, ->(user_id) { all.in(id: InterestedProject.where(user_id: user_id).in(status: %w(subscribed approved)).distinct(:project_id)) }
  scope :filter_by_regions, ->(regions) {regions.is_a?(Array) ? where( region: { "$in": regions }) : where(region: regions)}
  scope :filter_by_is_active, ->(is_active) { where(is_active: is_active.to_s == 'true') }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(name: regex ) }
  scope :filter_by_disable_project_walk_ins, ->(disabled_walkin) { where('disable_project.walk_ins': (disabled_walkin == 'true')) }
  scope :filter_by_disable_project_bookings, ->(disabled_bookings) { where('disable_project.bookings': (disabled_bookings == 'true')) }

  #def unit_configurations
  #  UnitConfiguration.where(data_attributes: {"$elemMatch" => {"n" => "project_id", "v" => self.selldo_id}})
  #end

  %w(logo mobile_logo cover_photo mobile_cover_photo).each do |uploader|
    define_method "#{uploader}_url" do
      self.send(uploader)&.url
    end
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
    Scheme.where(booking_portal_client_id: self.booking_portal_client_id, project_id: self.id, default: true).first
  end

  def enable_actual_inventory?(user)
    if user.present?
      enable_actual_inventory.include?(user.role)
    else
      false
    end
  end

  def ds_name
    n = name
    if city.present?
      n += " (#{city})"
    end
    n
  end

  def incentive_calculation_type?(_type)
    if _type.present?
      incentive_calculation.include?(_type)
    else
      false
    end
  end

  def cp_subscription_count
    InterestedProject.where(booking_portal_client_id: self.booking_portal_client_id, project_id: self.id).count
  end

  def is_subscribed(user)
    InterestedProject.where(booking_portal_client_id: self.booking_portal_client_id, project_id: self.id, user_id: user.id).in(status: %w(subscribed approved)).present?
  end

  def walk_ins_enabled?
    !self.disable_project['walk_ins']
  end

  def bookings_enabled?
    !self.disable_project['bookings']
  end

  def invoicing_enabled?
    !self.disable_project['invoicing']
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
    if user.role.in?(%w(superadmin))
      custom_scope = {  }
    elsif user.role.in?(%w(admin))
      custom_scope = {  }
    end

    if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
      custom_scope.merge!({_id: { "$in": project_ids }})
    end
    custom_scope.merge!({ is_active: true }) if (params[:controller] == 'admin/projects' && params[:action] == 'index') || params[:controller] == 'home'
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end

end
