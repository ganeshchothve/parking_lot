# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create product in kylas
  class CreateNote < BaseService

    attr_accessor :user, :note, :params

    def initialize(user, note, params={})
      @user = user
      @note = note
      @params = params
    end

    def call
      return if user.blank?

      response = create_note_in_kylas
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, data: JSON.parse(response.body) }
      when Net::HTTPBadRequest
        Rails.logger.error 'CreateProductInKylas - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'CreateProductInKylas - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'CreateProductInKylas - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'CreateProductInKylas - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    def create_note_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/notes/relation")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url, request_headers)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        payload = note_payload
        request.body = JSON.dump(payload)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end

    def note_payload
      note_payload = {
          "sourceEntity": {
              "description": "<div>#{note.note.html_safe}</div>"
          },
          "targetEntityId": note.notable.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)),
          "targetEntityType": "DEAL"
      }
    end
  end
end