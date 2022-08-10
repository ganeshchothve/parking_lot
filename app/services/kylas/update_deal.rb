require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Used for update deal
  class UpdateDeal
    attr_reader :user, :entity_id, :params

    def initialize(user, entity_id, params = {})
      @user = user
      @entity_id = entity_id
      @params = params.with_indifferent_access
    end

    def call
      return if user.blank? || entity_id.blank? || params.blank?

      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/deals/#{entity_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Patch.new(url)
      if user.kylas_api_key?
        request['api-key'] = user.kylas_api_key
      elsif user.kylas_refresh_token
        request['Authorization'] = "Bearer #{user.fetch_access_token}"
      end
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      payload = deal_payload
      request.body = JSON.dump(
        {
            'deal': payload,
            'executeWorkflow': true,
            'sendNotification': false
        }
      )
      response = https.request(request)
      api_log = ApiLog.new
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        api_log.assign_attributes(request_url: url, request: [payload], response: [(JSON.parse(response.body) rescue {})], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        dump_kylas_contact_id
        response = JSON.parse(response.body)
        { success: true, data: response }
      when Net::HTTPBadRequest
        Rails.logger.error 'UpdateDeal - 400'
        api_log.assign_attributes(request_url: url, request: ([(payload rescue {})]), response: [(JSON.parse(response.body) rescue {})], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'UpdateDeal - 404'
        api_log.assign_attributes(request_url: url, request: ([(payload rescue {})]), response: [(JSON.parse(response.message) rescue 'Invalid Data!')], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'UpdateDeal - 500'
        api_log.assign_attributes(request_url: url, request: ([(payload rescue {})]), response: [(JSON.parse(response.message) rescue 'Server Error!')], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'UpdateDeal - 401'
        api_log.assign_attributes(request_url: url, request: ([(payload rescue {})]), response: [(JSON.parse(response.message) rescue 'Unauthorized')], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Unauthorized' }
      else
        api_log.assign_attributes(request_url: url, request: ([(payload rescue {})]), response: [(JSON.parse(response.message) rescue 'Internal server error!')], resource: user, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false }
      end
    end

    private
    def deal_payload
      begin
        deal_params = {}
        if params[:contact].present?
          deal_params = update_contact
        end
        if params[:product].present?
          deal_params = update_product
        end
        deal_params
      rescue StandardError => e
        Rails.logger.error { e.message.to_s }
        { }
      end
    end

    # save kylas contact id to user
    def dump_kylas_contact_id
      if params[:contact].present?
        lead = Lead.where(kylas_deal_id: entity_id).first
        user = lead.user
        contact = params[:contact].with_indifferent_access
        user.update(kylas_contact_id: contact[:id])
      end
    end

    def update_contact
      contact = params[:contact]
      contact_payload = {
        associatedContacts:{
          operation: "ADD",
          values: [contact]
        }
      }
      contact_payload
    end

    def update_product
      product = params[:product]
      products_payload =  {
        products: {
          operation: 'ADD', 
          values: [
            {
              id: product['id'],
              name: product['name'], 
              quantity: 1,
              price: {
                currencyId: product.dig('price','currency' ,'id'),
                value: product.dig('price','value').to_f
              },
              discount: {
                type: 'PERCENTAGE', 
                value: 0.0
              }
            }
          ]
        }
      }
      products_payload
    end

  end
end