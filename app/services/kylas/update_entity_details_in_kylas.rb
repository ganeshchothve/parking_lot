# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to update entity details in kylas
  class UpdateEntityDetailsInKylas

    attr_accessor :user, :stage, :entity_id, :entity_type, :pipeline_id

    def initialize(user, stage, entity_id, entity_type, pipeline_id)
      @user = user
      @stage = stage
      @entity_id = entity_id
      @entity_type = entity_type
      @pipeline_id = pipeline_id
    end

    def update_pipeline_and_entity_value_in_kylas
      wf = Workflow.where(stage: stage, booking_portal_client_id: user.booking_portal_client.id).first
      if wf.present?
        workflow_pipeline = wf.pipelines.where(pipeline_id: pipeline_id).first
        if workflow_pipeline.present?
          #service to get the entity details
          response = Kylas::EntityDetails.new(user, entity_id, entity_type).call
          kylas_entity = response[:data] if response[:success]
          return if kylas_entity.blank?
          #create the request payload
          update_stage_params = {}
          update_stage_params['reasonForClosing'] = workflow_pipeline.lead_closed_reason.presence
          update_stage_params['products'] = kylas_entity['products']
          update_stage_params['actualValue'] = nil
          
          #service to update the entity pipeline stage
          Kylas::UpdateEntityPipelineStage.new(
            user, entity_id, entity_type, workflow_pipeline.pipeline_stage_id, update_stage_params
          ).call
        end
      end
    end
  end
end