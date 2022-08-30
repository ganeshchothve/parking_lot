module Kylas
  class CreateCustomField

    attr_reader :user, :cp_user, :options, :entity

    def initialize(user, cp_user = nil, options = {})
      @user = user
      @cp_user = cp_user
      @options = options
      @entity = options[:entity]
    end

    def call
      return unless user.present? && options.present? && entity.present?
      begin
        url = set_url(entity)
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url)
        if user.kylas_api_key?
          request['api-key'] = user.kylas_api_key
        else
          request['Authorization'] = "Bearer #{user.fetch_access_token}"
        end
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request.body = JSON.dump(custom_field_params)
        
        response = https.request(request)

        case response
        when Net::HTTPOK, Net::HTTPSuccess  
          parsed_response = JSON.parse(response.body)
          parsed_response = parsed_response.with_indifferent_access
          dump_kylas_field_ids(parsed_response)
          ApiLog.log_responses(url, [custom_field_params], [parsed_response], cp_user, 'Hash', user.booking_portal_client)
          { success: true, data: parsed_response }
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
    # contact and lead custom fields params
    def custom_field_params
      {
          displayName: 'Channel Partner',
          description: 'List of Channel Partners',
          pickLists: [
            {
              id: nil, 
              name: nil, 
              displayName: (cp_user.present? ? cp_user.name : 'Default CP'),
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

    def set_url(entity)
      if entity == 'lead' 
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/entities/#{entity}/fields?entityType=lead")
      elsif ['deals', 'meetings'].include?(entity)
        url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/#{entity}/fields")
      end
      url
    end

    def dump_kylas_field_ids(response)
      booking_portal_client = user.booking_portal_client
      booking_portal_client.set("kylas_custom_fields.#{entity}": (response[:id] rescue nil))
      if cp_user.present?
        if entity == 'lead'
          cp_user.set("kylas_custom_fields_option_id.#{entity}": (response[:pickLists].pluck(:id).first rescue nil))
        elsif ['deals', 'meetings'].include?(entity)
          cp_user.set("kylas_custom_fields_option_id.#{entity}": (response[:picklist][:picklistValues].pluck(:id).first rescue nil))
        end
      end
    end

  end
  
end