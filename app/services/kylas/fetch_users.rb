# frozen_string_literal: true

require 'net/http'

module Kylas
  # Service for fetch users
  class FetchUsers < BaseService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      users_json_response = fetch_users_request

      kylas_users_list = []
      if users_json_response && users_json_response['totalPages']
        kylas_users_list += parse_kylas_user_data(users_json_response)
        pages = users_json_response['totalPages']
        count = 1

        while count < pages
          json_resp = fetch_users_request({ page: count })
          kylas_users_list += parse_kylas_user_data(json_resp)
          count += 1
        end
      end
      kylas_users_list.compact
    end

    private

    def fetch_users_request(data = {})
      begin
        page = data[:page] || 0
        url = URI(base_url+"/users/search?sort=updatedAt,desc&page=#{page}&size=100")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        post_request = Net::HTTP::Post.new(url)
        post_request['Content-Type'] = 'application/json'

        if user.kylas_refresh_token
          post_request['Authorization'] = "Bearer #{user.fetch_access_token}"
        elsif user.kylas_api_key?
          post_request['api-key'] = user.kylas_api_key
        end
        post_request.body = { fields: %w[firstName lastName id email phoneNumbers active] }.to_json
        response = https.request(post_request)
        JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error { e.message.to_s }

        nil
      end
    end

    def parse_kylas_user_data(json_resp)
      json_resp['content']&.map do |content|
        [content['firstName'], content['lastName'], content['email'], content['phoneNumbers'][0], content['id'], content['active']]
      end
    end
  end
end
