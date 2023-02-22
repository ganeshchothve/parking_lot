module Kylas
  class FetchLeads < BaseService
    attr_reader :user, :options, :page_number, :page_size, :fields, :request_payload

    def initialize(user,  options = {})
      @user = user
      @options = options.with_indifferent_access
      @page_number = options[:page_number] || 0
      @page_size = options[:page_size] || 10
      @fields = options[:fields] || ["firstName", "lastName", "ownerId", "phoneNumbers", "emails", "id", "products"]
      @request_payload = options[:request_payload]
    end

    def call
      return if user.blank? && request_payload.blank?
      fetch_leads_request
    end

    private

    def fetch_leads_request
      begin
        response = kylas_request(page_size)

        if response&.code.eql?('200')
          {success: true, data: JSON.parse(response.body)}
        else
          Rails.logger.error { "FetchLeads: #{response&.body}" }
          {success: false, errors: (response&.message rescue "Error while fetching leads")}
        end
        rescue StandardError => e
        {success: false, errors: e.message}
      end
    end

    def kylas_request(page = 0)
      url = URI(base_url+"/search/lead?sort=updatedAt,desc&page=#{page_number}&size=#{page_size}")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url, request_headers)
      request_payload[:fields] = fields
      request.body = JSON.dump(request_payload) if request_payload.present?
      https.request(request)
    end

  end
end
