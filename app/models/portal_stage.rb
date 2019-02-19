class PortalStage
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :stage, type: String, default: '' # TODO: validation remaining

  # Associations
  embedded_in :user
end
