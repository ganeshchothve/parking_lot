class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

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
  field :rera_project_id, type: String
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

  mount_uploader :logo, DocUploader

  has_many :project_units
  has_many :project_towers
  has_one :address, as: :addressable
  belongs_to :booking_portal_client, class_name: 'Client'

  accepts_nested_attributes_for :address, allow_destroy: true #, :brochure_templates, :price_quote_templates, :images
  index(client_id:1)

  default_scope -> { where(is_active: true)}

  validates :name, :logo, :rera_registration_no, presence: true

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
end
