# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create product in kylas
  class CreateProductInKylas

    attr_accessor :user, :params

    def initialize(user, params={})
      @user = user
      @params = params
    end

    def call
      return if user.blank? || params.blank?

      response = create_product_in_kylas
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, response: JSON.parse(response.body) }
      when Net::HTTPBadRequest
        Rails.logger.error 'CreateProductInKylas - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'CreateProductInKylas - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'CreateProductInKylas - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'CreateProductInKylas - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    def create_product_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/products")

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
        payload = product_payload
        request.body = JSON.dump(payload)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    def product_payload
      product_payload = {
        "isActive": true,
        "name": params[:project_unit_name],
        "price": {
          "currencyId": 431,
          "value": params[:agreement_price]
        },
        "customFieldValues": {}
      }
    end
  end
end