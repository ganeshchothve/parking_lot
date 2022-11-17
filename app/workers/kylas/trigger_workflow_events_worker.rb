# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to trigger all the workflow events
  class TriggerWorkflowEventsWorker
    include Sidekiq::Worker

    def perform(entity_id, entity_class)
      entity = entity_class.constantize.where(id: entity_id).first
      trigger_workflow_events_in_kylas(entity) if entity.present?
    end

    def trigger_workflow_events_in_kylas(entity)
      wf = Workflow.where(stage: entity.status, booking_portal_client_id: entity.booking_portal_client.id, is_active: true).first
      deal_pipeline = wf.pipelines.where(entity_type: "deals").first if wf.present?
      kylas_deal_response = Kylas::UpdateDeal.new(entity.creator, entity.lead.kylas_deal_id, {pipeline: deal_pipeline.as_json}).call if deal_pipeline.present?
      if wf.present?

        # call serice to update the product on that deal
        if wf.create_product?
          product_params = create_product_payload(entity, wf)
          kylas_product_response = Kylas::CreateProductInKylas.new(entity.creator, product_params).call

          # call serice to update the product on that deal
          if wf.update_product_on_deal?
            #fetch deal details from Kylas
            fetch_deal_details = Kylas::FetchDealDetails.new(entity.lead.kylas_deal_id, entity.creator).call
            if fetch_deal_details[:success]
              deal_data = fetch_deal_details[:data].with_indifferent_access
              deal_associated_products = deal_data[:products].collect{|pd| [pd[:name], pd[:id]]} rescue []
              booking_product_in_kylas = deal_associated_products.select{ |kp| kp.include?(entity.kylas_product_id) } rescue []
              iris_project_on_deal = deal_data[:products].find { |kp| kp['id'].to_s == entity.project.kylas_product_id } rescue {}
              iris_project_on_deal[:price][:value] = 0 if iris_project_on_deal.present? && iris_project_on_deal.dig(:price, :value).present?
              #check whether the product is present on the deal or not
              if !(booking_product_in_kylas.present?)
                update_deal_params = {product: []}
                update_deal_params[:product] << iris_project_on_deal if iris_project_on_deal.present?
                update_deal_params[:product] << update_product_payload(kylas_product_response[:response]['id'], entity, wf) if kylas_product_response[:success]
                kylas_deal_response = Kylas::UpdateDeal.new(entity.creator, entity.lead.kylas_deal_id, update_deal_params).call
                entity.set(kylas_product_id: kylas_product_response[:response]['id']) if kylas_product_response[:success]
              end
            end

            # call service to deactivate the product in Kylas
            if wf.deactivate_product?
              product_deactivate_params = deactivate_product_params(entity)
              Kylas::DeactivateProduct.new(entity.creator, entity.kylas_product_id, product_deactivate_params).call
            end
          end
        end

        # call service to update the pipeline stage in kylas
        workflow_pipeline = wf.pipelines.where(pipeline_id: entity.lead.kylas_pipeline_id).first
        if workflow_pipeline.present?
          #service to get the entity details
          response = Kylas::EntityDetails.new(entity.creator, entity.lead.kylas_deal_id, "deals").call
          kylas_entity = response[:data] if response[:success]
          return if kylas_entity.blank?

          #create the request payload
          update_stage_params = update_pipeline_stage_params(workflow_pipeline, kylas_entity, entity)
          
          #service to update the entity pipeline stage
          Kylas::UpdateEntityPipelineStage.new(
            entity.creator, entity.lead.kylas_deal_id, "deals", workflow_pipeline.pipeline_stage_id, update_stage_params
          ).call
        end
      end
    end

    def create_product_payload(entity, wf)
      payload = {
        project_unit_name: entity.name,
        agreement_price: (wf.get_product_price.present? ? entity.send(wf.get_product_price) : 0)
      }
      payload
    end

    def update_product_payload(product_id, entity, wf)
      payload = {
        'id': product_id,
        'name': entity.name,
        'price': {
          'currency': {
            'id': 431
          },
          'value': (wf.get_product_price.present? ? entity.send(wf.get_product_price) : 0)
        }
      }
      payload
    end

    def deactivate_product_params(entity)
      payload = {
        kylas_product_id: entity.kylas_product_id,
        project_unit_name: entity.name,
        agreement_price: entity.agreement_price
      }
      payload
    end

    def update_pipeline_stage_params(workflow_pipeline, kylas_entity, entity)
      payload = {
        reasonForClosing: workflow_pipeline.lead_closed_reason.presence,
        products: kylas_entity['products'],
        actualValue: nil
      }
      payload
    end
  end

end