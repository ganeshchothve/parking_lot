class Phase
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  belongs_to :account
  has_many :project_units
end
