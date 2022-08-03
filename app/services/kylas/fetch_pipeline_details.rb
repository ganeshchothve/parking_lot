# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Service for fetch pipelines
  class FetchPipelineDetails
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

        response = kylas_request(page: page) if user.kylas_refresh_token.present?
        response = kylas_request(api_key: true, page: page) unless response&.code.eql?('200')
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

    def kylas_request(api_key: false, page: 0)
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/pipelines/search?sort=updatedAt,desc&page=#{page}&size=100")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)

      if api_key
        request['Api-Key'] = user.kylas_api_key
      else
        request['Authorization'] = "Bearer #{user.fetch_access_token}"
      end
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
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
