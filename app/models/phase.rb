class Phase
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  belongs_to :account, optional: true
  has_many :project_units
  belongs_to :project
  belongs_to :booking_portal_client, class_name: 'Client'
end
