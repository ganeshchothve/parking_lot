class PipelinePolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :entity_type, :pipeline_id, :pipeline_stage_id, :lead_closed_reason, :_destroy]
    attributes.uniq
  end
end
