require 'uri'
require 'json'
require 'net/http'

module Kylas
  class BaseService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    private
    def request_headers
      headers = {}
      headers['Content-Type'] = 'application/json'
      headers['Accept'] = 'application/json'
      if user.kylas_refresh_token
        headers['Authorization'] = "Bearer #{user.fetch_access_token}"
      elsif user.kylas_api_key?
        headers['api-key'] = user.kylas_api_key
      end
      headers
    end

    def base_url
      "#{ENV_CONFIG.dig(:kylas, :base_url)}/#{ENV_CONFIG.dig(:kylas, :version)}"
    end
  end
end