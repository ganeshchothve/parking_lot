class ProjectTower
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include CrmIntegration
  extend FilterByCriteria
  extend DocumentsConcern

  # Add different types of documents which are uploaded on project_tower
  DOCUMENT_TYPES = []

  field :name, type: String
  field :client_id, type: String
  field :project_name, type: String
  field :total_units, type: Hash
  field :total_floors, type: Integer
  field :total_builtup_area, type: Float
  field :units_per_floor, type: Integer
  field :maintenance, type: Float
  field :rate, type: Float
  field :total_plot_area, type: Float
  field :floor_rise_type, type: String
  field :floor_rise, type: Array, default: []
  field :floor_rise_rate, type: Float
  field :project_tower_approval, type: String
  field :possession_date, type: Date
  field :completion_date, type: Date
  field :project_tower_status, type: String
  field :selldo_id, type: String
  field :completed_floor, type: Integer
  field :project_tower_stage, type: String

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project
  has_many :project_units
  has_many :schemes

  validates :name, :project_id, :total_floors, presence: true
  validate :validate_floor_rise
  has_many :assets, as: :assetable

  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(name: regex ) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }

  def unit_configurations
    UnitConfiguration.where(booking_portal_client_id: self.booking_portal_client_id, data_attributes: { '$elemMatch' => { 'n' => 'project_tower_id', 'v' => selldo_id } })
  end

  def default_scheme
    Scheme.where(booking_portal_client_id: self.booking_portal_client_id, project_tower_id: id, default: true).first
  end

  private

  def validate_floor_rise
    arr = floor_rise.clone
    arr = arr.sort_by { |b| b['start_floor'].to_i }
    arr.each_with_index do |rec, index|
      if index > 0 && arr[index - 1]['end_floor'].to_i >= rec['start_floor'].to_i
        errors.add(:base, 'Enter valid Start floor and End Floor')
        break
      end
    end
  end
end
