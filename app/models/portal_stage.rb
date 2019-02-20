class PortalStage
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :stage, type: String, default: ''

  # Associations
  embedded_in :user

  # Validations
  validates :stage, uniqueness: true, presence: true
end
