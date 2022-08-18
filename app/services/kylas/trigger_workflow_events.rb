# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to trigger all the workflow events
  class TriggerWorkflowEvents

    attr_accessor :entity

    def initialize entity
      @entity = entity
    end

    def trigger_workflow_events_in_kylas
      wf = Workflow.where(stage: entity.status, booking_portal_client_id: entity.creator.booking_portal_client.id).first
      if wf.present?

        # call serice to update the product on that deal
        if wf.create_product?
          product_params = create_product_payload
          kylas_product_response = Kylas::CreateProductInKylas.new(entity.creator, product_params).call

          entity.set(kylas_product_id: kylas_product_response[:response]['id']) if kylas_product_response[:success]
        end

        # call serice to update the product on that deal
        if wf.update_product_on_deal?
          update_deal_params = {}
          update_deal_params[:product] = update_product_payload
          kylas_deal_response = Kylas::UpdateDeal.new(entity.creator, entity.lead.kylas_deal_id, update_deal_params).call
        end

        # call service to deactivate the product in Kylas
        if wf.deactivate_product?
          product_deactivate_params = deactivate_product_params
          Kylas::DeactivateProduct.new(entity.creator, entity.kylas_product_id, product_deactivate_params)
        end

        # call service to update the pipeline stage in kylas
        workflow_pipeline = wf.pipelines.where(pipeline_id: entity.lead.kylas_pipeline_id).first
        if workflow_pipeline.present?
          #service to get the entity details
          response = Kylas::EntityDetails.new(entity.creator, entity.lead.kylas_deal_id, "deals").call
          kylas_entity = response[:data] if response[:success]
          return if kylas_entity.blank?

          #create the request payload
          update_stage_params = update_pipeline_stage_params(workflow_pipeline, kylas_entity)
          
          #service to update the entity pipeline stage
          Kylas::UpdateEntityPipelineStage.new(
            entity.creator, entity.lead.kylas_deal_id, "deals", workflow_pipeline.pipeline_stage_id, update_stage_params
          ).call
        end
      end
    end

    def create_product_payload
      payload = {
        project_unit_name: entity.name,
        agreement_price: entity.agreement_price
      }
      payload
    end

    def update_product_payload
      payload = {
        'id': entity.kylas_product_id,
        'name': entity.name,
        'price': {
          'currency': {
            'id': 431
          },
          'value': entity.agreement_price
        }
      }
      payload
    end

    def deactivate_product_params
      payload = {
        kylas_product_id: entity.kylas_product_id,
        project_unit_name: entity.name,
        agreement_price: entity.agreement_price
      }
      payload
    end

    def update_pipeline_stage_params(workflow_pipeline, kylas_entity)
      payload = {
        reasonForClosing: workflow_pipeline.lead_closed_reason.presence,
        products: kylas_entity['products'],
        actualValue: nil
      }
      payload
    end
  end

end