class Developer
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :developer_rating, type: Integer
  field :selldo_id, type: String

  validates :name,:presence => true
  validates :name, uniqueness: {case_sensitive: false} #, scope: :client}

  has_many :project_units
  belongs_to :booking_portal_client, class_name: "Client"

  def unit_configurations
    UnitConfiguration.where(booking_portal_client_id: self.booking_portal_client_id, data_attributes: {"$elemMatch" => {"n" => "developer_id", "v" => self.selldo_id}})
  end

  def projects
    Project.or([{developer_id: self.selldo_id}, {secondary_developer_ids: self.selldo_id}]).where(booking_portal_client_id: self.booking_portal_client_id)
  end
end
