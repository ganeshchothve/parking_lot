# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Service for fetch pipelines
  class FetchPipelineDetails < BaseService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      pipelines_json_response = fetch_pipeline_request
      pipelines_list = []
      if pipelines_json_response && pipelines_json_response['totalPages']
        pipelines_list += parse_pipeline_data(pipelines_json_response)
        pages = pipelines_json_response['totalPages']
        count = 1

        while count < pages
          json_resp = fetch_pipeline_request({ page: count })
          pipelines_list += parse_pipeline_data(json_resp)
          count += 1
        end
      end
      pipelines_list.compact
    end

    private

    def fetch_pipeline_request(data = {})
      begin
        page = data[:page] || 0

        response = kylas_request(page: page)
        if response&.code.eql?('200')
          JSON.parse(response.body)
        else
          Rails.logger.error { "FetchPipelineDetails: #{response&.body}" }
          nil
        end
      rescue StandardError => e
        Rails.logger.error { "FetchPipelineDetails: #{e.message}" }
        nil
      end
    end

    def kylas_request(page: 0)
      url = URI(base_url+"/pipelines/search?sort=updatedAt,desc&page=#{page}&size=100")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url, request_headers)
      request.body = JSON.dump(
        {
          'fields': %w[name entityType active id],
          'jsonRule': {
            'rules': [
              {
                'operator': 'equal', 'id': 'active', 'field': 'active',
                'type': 'boolean', 'value': true
              }
            ],
            'condition': 'AND',
            'valid': true
          }
        }
      )
      https.request(request)
    end

    def parse_pipeline_data(json_resp)
      json_resp['content']&.map do |content|
        if content['entityType'] == 'DEAL'
          {
            pipeline_id: content['id'],
            pipeline_name: content['name'],
            pipeline_entity_type: content['entityType']
          }
        end
      end
    end
  end
end
