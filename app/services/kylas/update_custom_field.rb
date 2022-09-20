module Kylas
  class UpdateCustomField < BaseService

    attr_reader :user, :cp_user, :options

    def initialize(user, cp_user, options = {})
      @user = user
      @cp_user = cp_user
      @options = options
    end

    def call
      return unless user.present? && cp_user.present? && options.present?
      begin
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/entities/#{options[:entity]}/fields/#{options[:field_id]}?fieldId=#{options[:field_id]}")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Put.new(url, request_headers)
        request.body = JSON.dump(custom_field_params)
        response = https.request(request)

        case response
        when Net::HTTPOK, Net::HTTPSuccess
          ApiLog.log_responses(url, [custom_field_params], [JSON.parse(response.body)], cp_user, 'Hash', user.booking_portal_client)
          { success: true, data: JSON.parse(response.body) }
        when Net::HTTPBadRequest
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], cp_user, 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPNotFound
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], cp_user, 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPServerError
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], cp_user, 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPUnauthorized
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Unauthorized!")], cp_user, 'Hash', user.booking_portal_client)
          { success: false, message: "Unauthorized!" }
        else
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid data!")], cp_user, 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        end
      rescue => e
        ApiLog.log_responses(url, [custom_field_params], [e.message], cp_user, 'Hash', user.booking_portal_client)
        { success: false, error: e.message }
      end
    end

    private
    def custom_field_params
      {
          displayName: 'Channel Partner',
          description: 'List of Channel Partners',
          pickLists: [
            {
              id: nil, 
              name: nil, 
              displayName: cp_user.name,
            }
          ],
          filterable: false,
          sortable: false,
          standard: false,
          required: false,
          type: 'PICK_LIST',
          important: false 
      }
    end

  end
  
end