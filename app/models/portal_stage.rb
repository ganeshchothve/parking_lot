class PortalStage
  include Mongoid::Document

  # Fields
  field :stage, type: String, default: '' # TODO: validation remaining
  field :updated_at, type: DateTime # TODO: validation remaining

  # Associations
  embedded_in :user
end
