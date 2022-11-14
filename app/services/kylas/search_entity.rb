# frozen_string_literal: true

require 'net/http'

module Kylas
  # Search Entity
  class SearchEntity < BaseService
    attr_accessor :entity, :entity_type, :field, :user

    def initialize(entity, entity_type, field, user)
			@entity = entity
			@entity_type = entity_type
			@field = field
			@user = user
    end

    def call
			url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/search/#{entity_type}?sort=updatedAt,desc&page=0&size=10")
			https = Net::HTTP.new(url.host, url.port)
			https.use_ssl = true
			request = Net::HTTP::Post.new(url, request_headers)

			entity_value = find_entity_value_using_field
			payload = entity_payload(entity_value)
			request.body = JSON.dump(payload)
			response = https.request(request)

			case response
			when Net::HTTPOK, Net::HTTPSuccess
			parsed_response = JSON.parse(response.body)
			{ success: true, data: parsed_response }
			when Net::HTTPBadRequest
			Rails.logger.error 'SearchEntity - 400'
			{ success: false, error: 'Invalid Data!' }
			when Net::HTTPNotFound
			Rails.logger.error 'SearchEntity - 404'
			{ success: false, error: 'Invalid Data!' }
			when Net::HTTPServerError
			Rails.logger.error 'SearchEntity - 500'
			{ success: false, error: 'Server Error!' }
			when Net::HTTPUnauthorized
			Rails.logger.error 'SearchEntity - 401'
			{ success: false, error: 'Unauthorized' }
			else
			{ success: false }
			end
    end

		def find_entity_value_using_field
			entity_value = if field == "email"
				entity.email
			elsif field == "phone"
				entity.phone
			elsif field == "email_phone"
				entity.email + " " + entity.phone
			end
		end

    def entity_payload entity_value
			payload = {
        "fields": [
            "firstName",
            "lastName",
            "id",
            "customFieldValues"
        ],
        "jsonRule": {
            "rules": [
                {
                    "id": "multi_field",
                    "field": "multi_field",
                    "type": "multi_field",
                    "input": "multi_field",
                    "operator": "multi_field",
                    "value": entity_value
                }
            ],
            "condition": "AND",
            "valid": true
        }
      }
    end
  end
end
