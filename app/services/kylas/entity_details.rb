# frozen_string_literal: true

require 'net/http'

module Kylas
  # Service for fetch entity details
  class EntityDetails < BaseService
    attr_reader :user, :entity_id, :entity_type

    def initialize(user, entity_id, entity_type)
      @user = user
      @entity_id = entity_id
      @entity_type = entity_type
    end

    def call
      return if user.blank? || entity_id.blank? || entity_type.blank?

      response = fetch_kylas_entity

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

    def fetch_kylas_entity
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/#{entity_type}/#{entity_id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(url, request_headers)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
        nil
      end
    end
  end
end
