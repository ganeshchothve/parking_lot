# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to trigger all the workflow events
  class TriggerWorkflowEventsWorker
    include Sidekiq::Worker

    def perform(entity_id, workflow_id, entity_class)
      if entity_id.present? && workflow_id.present? && entity_class.present?
        entity = entity_class.constantize.where(id: entity_id).first
        trigger_workflow_events_in_kylas(entity, workflow_id) if workflow_id.present? && entity.present?
      end
    end

    def trigger_workflow_events_in_kylas(entity, workflow_id)
      wf = Workflow.where(id: workflow_id, booking_portal_client_id: entity.booking_portal_client.id, is_active: true).first

      if wf.present? && entity.lead.kylas_pipeline_id.blank?
        deal_pipeline = wf.pipelines.where(entity_type: "deals").first
        if deal_pipeline.present?
          response = Kylas::UpdateDeal.new(entity.creator, entity, {pipeline: deal_pipeline.as_json}).call
          api_log = response[:api_log]
          if api_log.present? && api_log.status == 'Success'
            entity.lead.update(kylas_pipeline_id: deal_pipeline.pipeline_id)
          end
        end
      end

      if wf.present?
        # call serice to update the product on that deal
        if wf.create_product?
          Kylas::CreateProductInKylas.new(entity.creator, entity, wf, {run_in_background: false}).call unless wf.update_product_on_deal?

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
                Kylas::CreateProductInKylas.new(entity.creator, entity, wf, {run_in_background: false}).call
                update_deal_params = {product: []}
                update_deal_params[:product] << iris_project_on_deal if iris_project_on_deal.present?
                entity.reload
                update_deal_params[:product] << update_product_payload(entity.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)), entity, wf) if entity.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).present?
                #update_deal_params.merge!({run_in_background: true})
                kylas_deal_response = Kylas::UpdateDeal.new(entity.creator, entity, update_deal_params).call
              end
            end

            # call service to deactivate the product in Kylas
            if wf.deactivate_product?
              Kylas::DeactivateProduct.new(entity.creator, entity, {run_in_background: true}).call
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

    def update_product_payload(product_id, entity, wf)
      payload = {
        'id': product_id,
        'name': entity.name,
        'price': {
          'currency': {
            'id': entity.booking_portal_client&.kylas_currency_id
          },
          'value': ((wf.get_product_price.present? && entity.respond_to?(wf.get_product_price)) ? entity.send(wf.get_product_price) : 0)
        }
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
