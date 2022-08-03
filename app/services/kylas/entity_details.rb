# frozen_string_literal: true

require 'net/http'

module Kylas
  # Service for fetch entity details
  class EntityDetails
    attr_reader :user, :entity_id, :entity_type

    def initialize(user, entity_id, entity_type)
      @user = user
      @entity_id = entity_id
      @entity_type = entity_type
    end

    def call
      return if user.blank? || entity_id.blank? || entity_type.blank?

      response = fetch_kylas_entity
      response = fetch_kylas_entity(auth_using_kylas_api: true) unless response.code.eql?('200')

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, data: JSON.parse(response.body) }
      when Net::HTTPBadRequest
        Rails.logger.error 'EntityDetails - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'EntityDetails - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'EntityDetails - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'EntityDetails - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    private

    def fetch_kylas_entity(auth_using_kylas_api: false)
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/#{entity_type}/#{entity_id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(url)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'

        # kylas-api-key or token
        if auth_using_kylas_api
          request['Api-Key'] = user.kylas_api_key
        else
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
