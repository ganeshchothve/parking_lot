# frozen_string_literal: true

require 'net/http'

module Kylas
  class FetchLeadCustomFieldDetails < BaseService
    attr_reader :user, :custom_field_id

    def initialize(user, custom_field_id)
      @user = user
      @custom_field_id = custom_field_id
    end

    def call
      return if user.blank? || custom_field_id.blank?
      url = URI("#{base_url}/fields/#{custom_field_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url, request_headers)
      response = https.request(request)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchLeadCustomFieldDetails - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchLeadCustomFieldDetails - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchLeadCustomFieldDetails - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchLeadCustomFieldDetails - 401'
        { success: false, error: 'Unauthorized!' }
      else
        { success: false }
      end
    end
  end
end
