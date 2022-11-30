# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Service for update entity pipeline details
  class UpdateEntityPipelineStage < BaseService
    attr_reader :user, :entity_id, :entity_type, :pipeline_stage_id, :parameters

    def initialize(user, entity_id, entity_type, pipeline_stage_id, parameters = {})
      @user = user
      @entity_id = entity_id
      @entity_type = entity_type
      @pipeline_stage_id = pipeline_stage_id.to_s
      @parameters = parameters
    end

    def call
      return if user.blank? || entity_id.blank? || entity_type.blank? || pipeline_stage_id.blank?

      response = update_pipeline_stage_kylas_entity
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

    def update_pipeline_stage_kylas_entity
      begin
        url = URI(base_url+"/#{entity_type}/#{entity_id}/pipeline-stages/#{pipeline_stage_id}/activate")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url, request_headers)
        request.body = JSON.dump(parameters)
        https.request(request)
      rescue StandardError => e
        Rails.logger.error e.message
        nil
      end
    end
  end
end
