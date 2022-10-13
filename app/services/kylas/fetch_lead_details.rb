# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch contact details
  class FetchLeadDetails < BaseService
    attr_reader :entity_id, :user

    def initialize(entity_id, user)
      @entity_id = entity_id
      @user = user
    end

    def call
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/leads/#{entity_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url, request_headers)

      response = https.request(request)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchDealDetails - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchDealDetails - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchDealDetails - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchDealDetails - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end
  end
end