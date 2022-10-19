# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to delete note in kylas
  class DeleteNote < BaseService

    attr_accessor :user, :note, :params

    def initialize(user, note, params={})
      @user = user
      @note = note
      @params = params
    end

    def call
      return if user.blank?

      response = delete_note_in_kylas

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true }
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

    def delete_note_in_kylas 
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/notes/#{note.kylas_note_id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Delete.new(url, request_headers)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        payload = {}
        request.body = JSON.dump(payload)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end
  end
end