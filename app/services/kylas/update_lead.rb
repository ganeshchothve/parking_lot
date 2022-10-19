# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to update lead in kylas
  class UpdateLead < BaseService

    attr_accessor :user, :entity_id, :params

    def initialize(user, entity_id, params={})
      @user = user
      @entity_id = entity_id
      @params = params
    end

    def call
      return if user.blank? || params.blank?

      response = update_lead_in_kylas
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, response: JSON.parse(response.body) }
      when Net::HTTPBadRequest
        Rails.logger.error 'UpdateLead - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'UpdateLead - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'UpdateLead - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'UpdateLead - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    def update_lead_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/leads/#{entity_id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Patch.new(url, request_headers)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request.body = JSON.dump(
          {
            'lead': leads_payload,
            'executeWorkflow': true,
            'sendNotification': false
          }
        )
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    def leads_payload
      lead = params[:lead]
      product = Project.where(kylas_product_id: lead['kylas_product_id']).first
      leads_payload =  {
        id: entity_id,
        firstName: lead['first_name'],
        lastName: lead['last_name'],
        products: {
          operation: 'ADD', 
          values: [
            {
              id: lead['kylas_product_id'],
              name: product.name, 
              quantity: 1
            }
          ]
        }
      }
      leads_payload
    end
  end
end