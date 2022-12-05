module Kylas
    class CreateProjectCustomField < BaseService
  
      attr_reader :user, :options
  
      def initialize(user, options = {})
        @user = user
        @options = options
      end
  
      def call
        return unless user.present?
        begin
          url = URI("#{base_url}/meetings/fields")
          https = Net::HTTP.new(url.host, url.port)
          https.use_ssl = true
          request = Net::HTTP::Post.new(url, request_headers)
          request.body = JSON.dump(project_cf_params)
          response = https.request(request)
  
          case response
          when Net::HTTPOK, Net::HTTPSuccess
            parsed_response = JSON.parse(response.body)
            parsed_response = parsed_response.with_indifferent_access
            dump_kylas_field_ids(parsed_response)
            ApiLog.log_responses(url, [project_cf_params], [parsed_response], (user), 'Hash', user.booking_portal_client)
            { success: true, data: parsed_response }
          when Net::HTTPBadRequest
            ApiLog.log_responses(url, [project_cf_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
            { success: false, message: "Invalid data!" }
          when Net::HTTPNotFound
            ApiLog.log_responses(url, [project_cf_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
            { success: false, message: "Invalid data!" }
          when Net::HTTPServerError
            ApiLog.log_responses(url, [project_cf_params], [(response.message rescue "Invalid Data!")], (user), 'Hash', user.booking_portal_client)
            { success: false, message: "Invalid data!" }
          when Net::HTTPUnauthorized
            ApiLog.log_responses(url, [project_cf_params], [(response.message rescue "Unauthorized!")], (user), 'Hash', user.booking_portal_client)
            { success: false, message: "Unauthorized!" }
          else
            ApiLog.log_responses(url, [project_cf_params], [(response.message rescue "Invalid data!")], (user), 'Hash', user.booking_portal_client)
            { success: false, message: "Invalid data!" }
          end
        rescue => e
          ApiLog.log_responses(url, [project_cf_params], [e.message], (user), 'Hash', user.booking_portal_client)
          { success: false, error: e.message }
        end
      end
  
      private
      def project_cf_params
        { 
            displayName: I18n.t('mongoid.attributes.client.project_meeting_custom_field'), 
            description: nil,
            pickLists: [
                {
                    id: nil,
                    name: nil,
                    displayName: 'Default Project',
                }
            ],
            filterable: true,
            sortable: false,
            standard: false,
            required: false,
            type: 'PICK_LIST', 
            important: false
        }
      end
  
      def dump_kylas_field_ids(response)
        booking_portal_client = user.booking_portal_client
        booking_portal_client.set("kylas_custom_fields.meeting_project": ({id: response[:id]} rescue nil))
        project_cf_id = booking_portal_client.kylas_custom_fields.dig('meeting_project', 'id')
        if project_cf_id.present?
          project_cf_response = Kylas::FetchMeetingCustomFieldDetails.new(user, project_cf_id).call
          if project_cf_response[:success]
            project_cf_response = project_cf_response.with_indifferent_access
            data = project_cf_response[:data]
            booking_portal_client.set("kylas_custom_fields.meeting_project": booking_portal_client.kylas_custom_fields.dig(:meeting_project).merge(name: data.dig(:field, :name), picklist_id: data.dig(:field, :picklist, :id)))
          end
        end
      end
    end
  end