module Kylas
  class UpdateDealCustomField < BaseService

    attr_reader :user, :cp_user, :custom_field_id, :options

    def initialize(user, cp_user, custom_field_id, options = {})
      @user = user
      @custom_field_id = custom_field_id
      @cp_user = cp_user
      @options = options
    end

    def call
      return unless user.present? && cp_user.present? && custom_field_id.present?
      begin
        url = URI("#{base_url}/deals/fields/#{custom_field_id}")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Put.new(url, request_headers)
        request.body = JSON.dump(custom_field_params)
        response = https.request(request)

        case response
        when Net::HTTPOK, Net::HTTPSuccess
          parsed_response = JSON.parse(response.body)
          parsed_response = parsed_response.with_indifferent_access
          dump_custom_field_option_values(parsed_response)
          ApiLog.log_responses(url, [custom_field_params], [parsed_response], (user), 'Hash', user.booking_portal_client)
          { success: true, data: parsed_response }
        when Net::HTTPBadRequest
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPNotFound
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPServerError
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        when Net::HTTPUnauthorized
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Unauthorized!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Unauthorized!" }
        else
          ApiLog.log_responses(url, [custom_field_params], [(response.message rescue "Invalid data!")], (user), 'Hash', user.booking_portal_client)
          { success: false, message: "Invalid data!" }
        end
      rescue => e
        ApiLog.log_responses(url, [custom_field_params], [e.message], (user), 'Hash', user.booking_portal_client)
        { success: false, error: e.message }
      end
    end

    private
    def custom_field_params
      { 
          displayName: I18n.t('mongoid.attributes.client.cp_deal_custom_field'),
          description: nil,
          pickLists: deal_custom_field_details,
          type: 'PICK_LIST',
          important: false,
          filterable: true,
          sortable: true,
          standard: false,
          required: false,
      }
    end

    def deal_custom_field_details
      response = Kylas::FetchDealCustomFieldDetails.new(user, custom_field_id).call
      if response[:success]
        data = response[:data].with_indifferent_access
        picklist_values = []
        picklist_values = data[:field][:picklist][:values].collect{|cf | {id: cf[:id], displayName: cf[:displayName]}  } rescue []
        picklist_values += [{id: nil, displayName: cp_user.name}] if picklist_values.present?
        picklist_values
      else
        []
      end
    end

    def dump_custom_field_option_values(response)
      begin
        data = response.with_indifferent_access
        pick_list_response = {}
        pick_list_response = data[:picklist][:picklistValues].find{|cf| cf[:displayName] == cp_user.name } rescue {}
        cp_user.set("kylas_custom_fields_option_id.deal": pick_list_response[:id]) if pick_list_response.present?
      rescue => exception
        Rails.logger.error "[Kylas::UpdateDealCustomField] - Error in dump_custom_field_option_values: #{exception.message} - response: #{response}"
      end
    end

  end
  
end