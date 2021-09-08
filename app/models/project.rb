class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include ArrayBlankRejectable
  include CrmIntegration
  include ApplicationHelper
  extend ApplicationHelper
  include ProjectOnboardingOnSelldo

  # Add different types of documents which are uploaded on client
  DOCUMENT_TYPES = %w[document brochure certificate unit_selection_filter_image sales_presentation images].freeze
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
  field :category, type: String
  field :project_segment, type: String
  field :possession, type: Date
  field :lat, type: String, default: '100'
  field :lng, type: String, default: '100'
  field :is_active,type: Boolean, default: true
  field :area_price_data, type: Array, default: []
  field :configurations, type: Array, default: []
  field :micro_market, type: String
  field :city, type: String
  field :project_type, type: String, default: "residential"

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
  field :project_size, type: String

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
  field :allowed_bookings_per_user, type: Integer, default: 3
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
  field :ga_code, type: String
  field :gtm_tag, type: String
  field :gst_number, type: String
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
      If you have any queries you can reach us at <%= current_project.support_number %> or write to us at <%= current_project.support_email %>. Please click <a href="<%= current_client.website_link %>">here</a> to visit our website.
    </div>
    <hr/>
    <div class="text-muted text-center" style="font-size: 12px;">
      © <%= Date.today.year %> <%= current_project.name %>. All Rights Reserved. | MAHARERA ID: <%= current_project.rera_registration_no %>
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
  mount_uploader :cover_photo, DocUploader
  mount_uploader :mobile_cover_photo, DocUploader

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :developer
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

  validates :name, presence: true
  validates_uniqueness_of :name, :rera_registration_no, allow_blank: true
  validates :enable_actual_inventory, array: { inclusion: {allow_blank: true, in: (User::ADMIN_ROLES + User::BUYER_ROLES) } }
  validates :ga_code, format: {with: /\Aua-\d{4,9}-\d{1,4}\z/i, message: 'is not valid'}, allow_blank: true

  accepts_nested_attributes_for :specifications, :offers, :timeline_updates, :address, allow_destroy: true

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

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    if user.role?('channel_partner')
      custom_scope = { _id: { '$in': user.interested_projects.approved.distinct(:project_id) } } unless params[:controller] == 'admin/projects'
    end

    unless user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
      if user.selected_project_id.present?
        custom_scope.merge!({_id: user.selected_project_id})
      elsif user.project_ids.present?
        project_ids = user.project_ids.map{|project_id| BSON::ObjectId(project_id) }
        custom_scope.merge!({_id: {"$in": project_ids}})
      end
    end
    custom_scope
  end
end
