# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch standard values of kylas
  class FetchStandardPickList
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      response = standard_picklist_request

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        { success: true, currencies: parsed_response['CURRENCY'] }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchStandardPickList - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchStandardPickList - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchStandardPickList - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchStandardPickList - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    private

    def standard_picklist_request
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/picklists/standard")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(url)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'

        if user.kylas_api_key?
          request['api-key'] = user.kylas_api_key
        elsif user.kylas_refresh_token
          request['Authorization'] = "Bearer #{user.fetch_access_token}"
        end

        # request
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
        nil
      end
    end
  end
end
