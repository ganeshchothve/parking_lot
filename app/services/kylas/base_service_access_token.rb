# frozen_string_literal: true

require 'rest-client'

module Kylas
  # Base service for request Access Token
  class BaseServiceAccessToken
    attr_reader :code_or_refresh_token

    def initialize(code_or_refresh_token)
      @code_or_refresh_token = code_or_refresh_token
    end

    def call
      return { success: false, error_message: I18n.t('kylas_auth.code_or_refresh_token_blank') } if code_or_refresh_token.blank?

      begin
        response = RestClient.post(
          api_call_url, {},
          {
            'Authorization' => "Basic #{encoded_credentials}",
            'Content-Type' => 'application/x-www-form-urlencoded'
          }
        )
        if response.code.eql?(200)
          res = JSON.parse(response.body)
          {
            success: true,
            access_token: res['access_token'],
            refresh_token: res['refresh_token'],
            expires_in: res['expires_in'].to_i
          }
        else
          { success: false, error_message: response.body }
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

    private

    def encoded_credentials
      cred = "#{ENV_CONFIG[:kylas][:client_id]}:#{ENV_CONFIG[:kylas][:client_secret]}"
      Base64::encode64(cred).gsub("\n", '')
    end
  end
end
