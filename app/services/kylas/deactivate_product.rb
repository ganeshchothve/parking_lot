# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to update entity details in kylas
  class DeactivateProduct

    attr_accessor :user, :entity_id, :params

    def initialize(user, entity_id, params={})
      @user = user
      @entity_id = entity_id
      @params = params
    end

    def call
      return if user.blank? || params.blank?

      response = deactivate_product_in_kylas
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true }
      when Net::HTTPBadRequest
        Rails.logger.error 'UpdateEntityPipelineStage - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'UpdateEntityPipelineStage - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'UpdateEntityPipelineStage - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'UpdateEntityPipelineStage - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    def deactivate_product_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/products/#{entity_id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url)

        if user.kylas_api_key?
          request['api-key'] = user.kylas_api_key
        elsif user.kylas_refresh_token
          request['Authorization'] = "Bearer #{user.fetch_access_token}"
        end

        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        payload = deactivate_product_payload
        request.body = JSON.dump(payload)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    def deactivate_product_payload
      deactivate_product_payload = {
        "id": params[:kylas_product_id],
        "name": params[:project_unit_name],
        "price": {
          "currencyId": 431,
          "value": params[:agreement_price]
        },
        "description": "NA",
        "isActive": false  # to be kept as false to deactivate that product
      }
    end
  end
end