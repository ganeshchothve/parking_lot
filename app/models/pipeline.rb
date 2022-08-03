class Pipeline
  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_type, type: String
  field :pipeline_id, type: Integer
  field :pipeline_stage_id, type: Integer
  field :lead_closed_reason, type: String

  belongs_to :workflow
end