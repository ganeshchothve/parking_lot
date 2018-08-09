class Developer
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String

  field :selldo_id, type: String
  field :client_id, type: String

  validates :name, :client_id,:presence => true
  validates :name, uniqueness: {case_sensitive: false} #, scope: :client}

  has_many :project_units
  belongs_to :booking_portal_client, class_name: "Client"

  def unit_configurations
    UnitConfiguration.where(data_attributes: {"$elemMatch" => {"n" => "developer_id", "v" => self.selldo_id}})
  end

  def projects
    Project.or([{developer_id: self.selldo_id}, {secondary_developer_ids: self.selldo_id}])
  end
end
