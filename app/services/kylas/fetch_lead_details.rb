# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch lead details
  class FetchLeadDetails < BaseService
    attr_reader :entity_id, :user

    def initialize(entity_id, user)
      @entity_id = entity_id
      @user = user
    end

    def call
      url = URI(base_url+"/leads/#{entity_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url, request_headers)

      response = https.request(request)
      parsed_response = JSON.parse(response.body)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchDealDetails - 400'
        { success: false, error: 'Invalid Data!', response: parsed_response }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchDealDetails - 404'
        { success: false, error: 'Invalid Data!', response: parsed_response }
      when Net::HTTPServerError
        Rails.logger.error 'FetchDealDetails - 500'
        { success: false, error: 'Server Error!', response: parsed_response }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchDealDetails - 401'
        { success: false, error: 'Unauthorized', response: parsed_response }
      else
        { success: false, response: parsed_response }
      end
    end
  end
end