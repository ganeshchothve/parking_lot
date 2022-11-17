# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create product in kylas
  class CreateWebhook < BaseService

    attr_accessor :user, :params

    def initialize(user, params={})
      @user = user
      @params = params
    end

    def call
      return if user.blank?

      response = create_webhook_in_kylas
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, response: JSON.parse(response.body) }
      when Net::HTTPBadRequest
        Rails.logger.error 'CreateWebhook - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'CreateWebhook - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'CreateWebhook - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'CreateWebhook - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    def create_webhook_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/webhooks")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url, request_headers)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        payload = webhook_payload
        request.body = JSON.dump(payload)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    def webhook_payload
        webhook_payload = {
            "name": "User Webhook",
            "requestType": "POST",
            "url": "#{IRIS_MARKETPLACE_HOST}/api/#{APP_KYLAS_VERSION}/users/create_or_update_user",
            "authenticationType": "NONE",
            "events": [
                "USER_CREATED",
                "USER_UPDATED",
                "USER_ACTIVATED",
                "USER_DEACTIVATED"
            ],
            "active": true
        }
    end
  end
end