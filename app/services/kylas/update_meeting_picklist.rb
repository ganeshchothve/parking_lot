module Kylas
  class UpdateMeetingPicklist < BaseService

    attr_reader :user, :cp_user, :options, :picklist_id, :picklist_value_id

    def initialize(user, cp_user, options = {})
      @user = user
      @cp_user = cp_user
      @options = options
      @picklist_value_id = @cp_user.kylas_custom_fields_option_id[:meeting] if @cp_user.present?
      @picklist_id = @user.booking_portal_client.kylas_custom_fields.dig(:meeting, :picklist_id) if @user.present?
    end

    def call
      return unless user.present? && cp_user.present? && picklist_id.present? && picklist_value_id.present?
      begin
        url = URI("#{base_url}/meetings/picklist/#{picklist_id}/picklist-value/#{picklist_value_id}")
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
        id: (cp_user.kylas_custom_fields_option_id[:meeting] rescue nil),
        displayName: cp_user.name
      }
    end

  end
  
end