class PortalStage
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :stage, type: String, default: ''
  field :priority, type: Integer

  # Associations
  embedded_in :lead

end
