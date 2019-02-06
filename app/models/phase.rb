class Phase
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  has_one :account
  has_many :project_units
end
