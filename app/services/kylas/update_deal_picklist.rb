module Kylas
  class UpdateDealPicklist < BaseService

    attr_reader :user, :cp_user, :options, :picklist_id

    def initialize(user, cp_user, options = {})
      @user = user
      @cp_user = cp_user
      @options = options
      @picklist_id = @cp_user.kylas_custom_fields_option_id[:deal] if @cp_user.present?
    end

    def call
      return unless user.present? && cp_user.present? && picklist_id.present?
      begin
        url = URI("#{base_url}/deals/picklists/picklist-values/#{picklist_id}")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Put.new(url, request_headers)
        request.body = JSON.dump(picklist_params)
        response = https.request(request)

        case response
        when Net::HTTPOK, Net::HTTPSuccess
          parsed_response = JSON.parse(response.body)
          parsed_response = parsed_response.with_indifferent_access
          ApiLog.log_responses(url, [picklist_params], [parsed_response], (user), 'Hash', user.booking_portal_client)
          { success: true, data: parsed_response }
        when Net::HTTPBadRequest
          ApiLog.log_responses(url, [picklist_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPNotFound
          ApiLog.log_responses(url, [picklist_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPServerError
          ApiLog.log_responses(url, [picklist_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPUnauthorized
          ApiLog.log_responses(url, [picklist_params], [(response.message rescue "Unauthorized!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Unauthorized!" }
        else
          ApiLog.log_responses(url, [picklist_params], [(response.message rescue "Invalid data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        end
      rescue => e
        ApiLog.log_responses(url, [picklist_params], [e.message], (user), 'Hash', user.booking_portal_client)
        { success: false, error: e.message }
      end
    end

    private
    
    def picklist_params
      {
        id: (cp_user.kylas_custom_fields_option_id[:deal] rescue nil),
        name: cp_user.name
      }
    end

  end
  
end