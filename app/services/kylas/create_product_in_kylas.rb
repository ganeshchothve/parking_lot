# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create product in kylas
  class CreateProductInKylas < BaseService

    attr_accessor :user, :entity, :wf, :params

    def initialize(user, entity, wf, params={})
      @user = user
      @entity = entity
      @wf = wf
      @params = params
    end

    def call
      return if user.blank? || params.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'BookingDetail', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          product_params = create_product_payload(entity, wf)
          if params[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'BookingDetail', entity.id, product_params)
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'BookingDetail', entity.id, product_params)
          end

          if response.present?
            log_response = response[:api_log]
            if log_response.present?
              if log_response[:status] == "Success"
                entity.set(kylas_product_id: log_response[:response].first.try(:[], "id")) if log_response[:response].present?
              end
            end
          end
        end
      end
    end

    def create_product_payload(entity, wf)
      payload = {
        agreement_price: ((wf.get_product_price.present? && entity.respond_to?(wf.get_product_price)) ? entity.send(wf.get_product_price) : 0)
      }
      payload
    end
  end
end