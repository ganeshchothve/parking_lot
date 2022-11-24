# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch uniqueness strategy details
  class FetchUniquenessStrategy < BaseService
    attr_reader :entity, :user

    def initialize(entity, user)
      @entity = entity
      @user = user
    end

    def call
      url = URI(base_url+"/configurations/uniqueness/#{entity}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url, request_headers)

      response = https.request(request)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchUniquenessStrategy - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchUniquenessStrategy - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchUniquenessStrategy - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchUniquenessStrategy - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end
  end
end
