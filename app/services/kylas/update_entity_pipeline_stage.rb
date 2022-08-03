# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Service for update entity pipeline details
  class UpdateEntityPipelineStage
    attr_reader :user, :entity_id, :entity_type, :pipeline_stage_id, :parameters

    def initialize(user, entity_id, entity_type, pipeline_stage_id, parameters = {})
      @user = user
      @entity_id = entity_id
      @entity_type = entity_type
      @pipeline_stage_id = pipeline_stage_id
      @parameters = parameters
    end

    def call
      return if user.blank? || entity_id.blank? || entity_type.blank? || pipeline_stage_id.blank?

      response = update_pipeline_stage_kylas_entity
      response = update_pipeline_stage_kylas_entity(auth_using_kylas_api: true) unless response.code.eql?('200')

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true }
      when Net::HTTPBadRequest
        Rails.logger.error 'UpdateEntityPipelineStage - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'UpdateEntityPipelineStage - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'UpdateEntityPipelineStage - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'UpdateEntityPipelineStage - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    private

    def update_pipeline_stage_kylas_entity(auth_using_kylas_api: false)
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/#{entity_type}/#{entity_id}/pipeline-stages/#{pipeline_stage_id}/activate")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request['Accept'] = 'application/json'
        request['Content-Type'] = 'application/json'
        if auth_using_kylas_api
          request['Api-Key'] = user.kylas_api_key
        else
          request['Authorization'] = "Bearer #{user.fetch_access_token}"
        end
        request.body = JSON.dump(parameters)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
        nil
      end
    end
  end
end
