class PipelinePolicy < ApplicationPolicy
  def permitted_attributes
    attributes = super
    attributes += [:id, :entity_type, :pipeline_id, :pipeline_stage_id, :lead_closed_reason, :_destroy, :booking_portal_client_id]
    attributes.uniq
  end
end
