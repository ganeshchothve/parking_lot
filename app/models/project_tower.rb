class ProjectTower
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :client_id, type: String
  field :project_name, type: String
  field :total_units, type: Hash
  field :total_floors, type: Integer
  field :total_builtup_area, type: Float
  field :units_per_floor, type: Integer
  field :maintenance, type: Float
  field :rate, type: Float
  field :max_discount, type: Float
  field :total_plot_area ,type: Float
  field :floor_rise_type , type: String
  field :floor_rise , type: Array,default: []
  field :floor_rise_rate, type: Float
  field :project_tower_approval,type: String
  field :possession_date,type: Date
  field :completion_date,type: Date
  field :project_tower_status,type: String
  field :selldo_id, type: String
  field :project_id, type: String
  field :completed_floor, type: Integer
  field :project_tower_stage, type: String

  belongs_to :project
  has_many :project_units

  validates :name, :client_id, :project_id, :total_floors, presence: true
  validate :validate_floor_rise
  has_many :assets, as: :assetable

  def unit_configurations
    UnitConfiguration.where(data_attributes: {"$elemMatch" => {"n" => "project_tower_id", "v" => self.selldo_id}})
  end

  private
  def validate_floor_rise
    arr = self.floor_rise.clone
    arr = arr.sort_by{|b| b["start_floor"].to_i}
    arr.each_with_index do |rec,index|
      if(index > 0 && arr[index - 1]["end_floor"].to_i >= rec["start_floor"].to_i)
        self.errors.add(:base,"Enter valid Start floor and End Floor")
        break
      end
    end
  end
end
