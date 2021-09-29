class UnitConfiguration
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  # Add different types of documents which are uploaded on unit_configuration
  DOCUMENT_TYPES = ['floor_plan', 'image']

  field :data_attributes, type: Array, default: []
  field :selldo_id, type: String
  field :images, type: Array,default: []
  field :is_active,type: Boolean, default: true
  field :sync_data,type: Boolean
  field :unit_configuration_active, type: String, default: "Yes"
  field :promoted, type: Boolean, default: false
  field :offers, type: Boolean, default: false

  validates :name, presence: true
  validates :saleable,:carpet,:base_rate,:numericality => {:greater_than => 0}

  belongs_to :project
  has_many :project_units
  has_many :assets, as: :assetable

  default_scope -> { where(:unit_configuration_active=> {"$ne" => "No"})}

  keys =  {name: "String",project_tower_name: "String", project_name: "String", developer_name: "String", bedrooms: "Float", bathrooms: "Float", saleable: "Float", carpet: "Float", loading: "Float", base_rate: "Float", base_price: "Float", sub_type: "String", type: "String", covered_area: "Float", terrace_area: "Float", category: "String",client_id: "String",developer_id: "String",selldo_project_id: "String",project_tower_id: "String",configuration_type: "String",project_status: "String",address1: "String",address2: "String",city: "String",state: "String",country: "String",amenities: "Array",balcony_description: "String",balcony_area: "Float",tag_brochure_project: "Boolean",tag_price_quote_project: "Boolean",apartment_size_type: "String",segment: "String",possession: "Date",approved_banks: "Array",approval: "String",rating: "String",launched_on: "Date",tag: "String",project_status_order: "Integer",administration: "String",project_size: "String",zone: "String", apartment_size: "String",secondary_developer_ids: "Array",secondary_developer_names: "Array"}

  keys.each do |k, klass|
    define_method(k) do
      if self.data_attributes.collect{|x| x['n']}.include?("#{k}")
        val = self.data_attributes.find { |h| h['n'] == "#{k}" }['v']
        case "#{klass}"
        when "String"
          val
        when "Integer"
          val.to_i
        when "Float"
          val.to_f
        else
          val
        end
      elsif "#{klass}" == "String"
        ""
      elsif "#{klass}" == "Integer"
        0
      elsif "#{klass}" == "Float"
        0.0
      elsif "#{klass}" == "Array"
        []
      else
	     nil
      end
    end

    attr_accessor "#{k}_changed"
    define_method("#{k}_changed") do
      instance_variable_get("@#{k}_changed") || false
    end

    define_method("#{k}=") do |arg|
      val = arg
      case "#{klass}"
      when "String"
        val = arg
      when "Integer"
        val = arg.to_i
      when "Float"
        val = arg.to_f
      when "Array"
        val = arg
      else
	     val = arg
      end
      if self.data_attributes.collect{|x| x['n']}.include?("#{k}")
        unless self.send(k) == val
          self.data_attributes.find { |h| h['n'] == "#{k}" }['v'] = val
          self.send("#{k}_changed=", true)
        end
      else
        self.data_attributes.push({"n" => "#{k}", "v" => val})
      end
    end
  end

  #def project
	#   Project.find_by_selldo_id(self.project_id) rescue nil
  #end

  def project_tower
    project_tower_id=self.data_attributes.find { |h| h['n'] == "project_tower_id" }['v']
    ProjectTower.find(project_tower_id) rescue nil
  end
end
