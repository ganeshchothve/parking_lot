class PortalStagePriority
  include Mongoid::Document
  include Mongoid::Timestamps

  field :stage, type: String
  field :priority, type: Integer
  field :role, type: String, default: 'user'

  validates :stage, :priority, :role, presence: true

  belongs_to :booking_portal_client, class_name: 'Client', optional: true

end
