module Kylas
  # Service for fetch products
  class FetchProducts < BaseService
    attr_reader :user, :product_ids

    def initialize(user, product_ids = nil)
      @user = user
      @product_ids = product_ids
    end

    def call(detail_response = false)
      products_json_response = fetch_products_request

      kylas_users_list = []
      if products_json_response && products_json_response['totalPages']
        if detail_response
          kylas_users_list += parse_kylas_product_data_detail_response(products_json_response)
        else
          kylas_users_list += parse_kylas_product_data(products_json_response)
        end
        pages = products_json_response['totalPages']
        count = 1
        while count < pages
          json_resp = fetch_products_request({ page: count })
          if detail_response
            kylas_users_list += parse_kylas_product_data_detail_response(json_resp)
          else
            kylas_users_list += parse_kylas_product_data(json_resp)
          end
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
        post_request = Net::HTTP::Post.new(url, request_headers)
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

    def parse_kylas_product_data_detail_response(json_resp)
      json_resp['content']&.map do |content|
        content
      end
    end
  end
end