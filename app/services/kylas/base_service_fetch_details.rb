# frozen_string_literal: true

require 'rest-client'

module Kylas
  # Base service for request Access Token
  class BaseServiceFetchDetails
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      begin
        if user.kylas_refresh_token
          access_token = user.fetch_access_token
          response = RestClient.get(
            api_call_url, { content_type: :json, 'Authorization' => "Bearer #{access_token}" }
          )
        elsif user.kylas_api_key?
          response = RestClient.get(
            api_call_url, { content_type: :json, 'api-key': user.kylas_api_key }
          )
        end
        if response&.code.eql?(200)
          { success: true, data: JSON.parse(response.body) }
        else
          { success: false }
        end
      rescue RestClient::NotFound
        Rails.logger.error "#{self.class} - 404"
        { error_message: 'Invalid Data!', success: false }
      rescue RestClient::InternalServerError
        Rails.logger.error "#{self.class} - 500"
        { error_message: 'Internal server error!', success: false }
      rescue RestClient::BadRequest
        Rails.logger.error "#{self.class} - 400"
        { error_message: 'Invalid Data!', success: false }
      end
    end
  end
end
