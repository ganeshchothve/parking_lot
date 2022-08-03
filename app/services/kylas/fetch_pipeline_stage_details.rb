# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch pipeline stages details
  class FetchPipelineStageDetails
    attr_reader :user_id, :pipeline_id

    def initialize(user_id, pipeline_id)
      @user_id = user_id
      @pipeline_id = pipeline_id
    end

    def call
      @user = User.find_by(id: user_id)
      return { success: false, error: I18n.t('user_not_found') } if @user.blank?

      response = kylas_request if @user.kylas_refresh_token.present?
      response = kylas_request(api_key: true) unless response&.code.eql?('200')

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, data: pipeline_stages_details(JSON.parse(response.body)) }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchPipelineStageDetails - 400'
        { success: false, error: 'Invalid Data! - 400' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchPipelineStageDetails - 404'
        { success: false, error: 'Invalid Data! - 404' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchPipelineStageDetails - 500'
        { success: false, error: 'Server Error! - 500' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchPipelineStageDetails - 401'
        { success: false, error: 'Unauthorized - 401' }
      else
        { success: false, error: 'Something went wrong!'}
      end
    end

    private

    def pipeline_stages_details(parsed_response)
      stages_details = parsed_response['stages'].map do |stage|
        forecasting_type = stage['forecastingType']
        result = {
          pipeline_stage_id: stage['id'],
          pipeline_stage_name: stage['name'],
          forecasting_type: forecasting_type
        }
        case forecasting_type
        when CLOSED_UNQUALIFIED_FORECASTING_TYPE
          result.merge!(reasons: parsed_response['unqualifiedReasons'])
        when CLOSED_LOST_FORECASTING_TYPE
          result.merge!(reasons: parsed_response['lostReasons'])
        end
        result
      end

      { stages_details: stages_details }
    end

    def kylas_request(api_key: false)
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/pipelines/#{pipeline_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      if api_key
        request['Api-Key'] = @user.kylas_api_key
      else
        request['Authorization'] = "Bearer #{@user.fetch_access_token}"
      end
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      https.request(request)
    end
  end
end
