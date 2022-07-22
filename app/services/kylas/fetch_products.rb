module Kylas
  # Service for fetch products
  class FetchProducts
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      products_json_response = fetch_products_request

      kylas_users_list = []
      if products_json_response && products_json_response['totalPages']
        kylas_users_list += parse_kylas_product_data(products_json_response)
        pages = products_json_response['totalPages']
        count = 1

        while count < pages
          json_resp = fetch_products_request({ page: count })
          kylas_users_list += parse_kylas_product_data(json_resp)
          count += 1
        end
      end
      kylas_users_list
    end

    private

    def fetch_products_request(data = {})
      begin
        page = data[:page] || 0
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/products/search?sort=updatedAt,desc&page=#{page}&size=100")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        post_request = Net::HTTP::Post.new(url)
        post_request['Content-Type'] = 'application/json'
        if user.kylas_api_key?
          post_request['api-key'] = user.kylas_api_key
        elsif user.kylas_refresh_token
          post_request['Authorization'] = "Bearer #{user.fetch_access_token}"
        end
        post_request.body = { fields: %w[name id] }.to_json
        response = https.request(post_request)
        JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error { e.message.to_s }

        nil
      end
    end

    def parse_kylas_product_data(json_resp)
      json_resp['content']&.map do |content|
        ["#{content['name']}", content['id']]
      end
    end
  end
end