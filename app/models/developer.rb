class Developer
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :website, type: String
  field :rating, type: String
  field :comments, type: String
  field :description, type: String

  field :selldo_id, type: String
  field :logo, type: Hash
  field :client_id, type: String
  field :secondary_project_ids, type: Array, default: []

  has_one :address, as: :addressable

  validates :name,:description,:client_id,:presence => true
  validates :website,format: {with: /((?:https?\:\/\/|www\.)(?:[-a-z0-9]+\.)*[-a-z0-9]+.*)/i},:allow_blank => true
  validates :name, uniqueness: {case_sensitive: false} #, scope: :client}
  accepts_nested_attributes_for :address, allow_destroy: true

  def unit_configurations
    UnitConfiguration.where(data_attributes: {"$elemMatch" => {"n" => "developer_id", "v" => self.selldo_id}})
  end

  def projects
    Project.or([{developer_id: self.selldo_id}, {secondary_developer_ids: self.selldo_id}])
  end
end
