module Api
  class Syncc
    attr_accessor :synclog, :request_payload, :response_payload, :record, :parent_sync, :erp_model, :url, :erp_id

    def initialize(erp_model, record, parent_sync_record = nil)
      @erp_model = erp_model
      @parent_sync = parent_sync_record
      @synclog = SyncLog.new
      @record = record
      @request_payload = {}
      @response_payload = {}
      #      <domain>         / <YML-URL>
      # 'http://selldo.com/vi/booking_details' / 'user'
      @url = erp_model.domain + '/' + erp_model.url
    end

    def execute
      request_payload = set_request_payload
      get_response
      update_erp_id if erp_model.action_name == 'create'
    end

    private


    def update_successful
      puts "#{erp_model.resource_class} #{erp_model.reference_key_name} updated successfully"
    end

    def update_failed
      raise Api::SyncError, "Could not update #{erp_model.resource_class} #{erp_model.reference_key_name}"
    rescue SyncError => e
      puts e.message
    end

    def validate_erp_id
      if get_erp_id.blank?
        raise Api::SyncError, "#{erp_model.resource_class} #{erp_model.reference_key_name} is required"
      elsif request_payload[:erp_id].present? && (request_payload[:erp_id] != get_erp_id)
        raise Api::SyncError, "#{erp_model.resource_class} #{erp_model.reference_key_name} in request and response must be the same"
      else
        true
      end
    end

    def set_request_payload
      erb = ERB.new(erp_model.request_payload)
      SafeParser.new(erb.result(binding)).safe_load #TO DO Error Handling
    end

    def set_sync_log(request, response, response_code, status, message)
      synclog.update_attributes(request: request, response: response, response_code: response_code, status: status, message: message, action: erp_model.action_name, resource: record, user_reference: record_user, reference: parent_sync)
    end

    def set_response_payload(response)
      response_payload = response[:body][erp_model.resource_class.to_sym]
      validate_erp_id
    end

    def get_erp_id
      response = response_payload
      erp_model.reference_key_location.split(',').each do |key|
        #will be ", " according to format
        response = response[key.to_sym] if response[key.to_sym].present?
      end
      erp_id = response[erp_model.reference_key_name.to_sym]
    end

    def get_response
      begin
        body = { body: {} }
        body[:body][erp_model.resource_class.to_sym] = request_payload
        if erp_model.action_name == 'create'
          response = HTTParty.post(@url.to_str, body.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
        elsif erp_model.action_name == 'update'
          response = HTTParty.patch(@url.to_str, body.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
        end
        case response.code # Check
        when 400..511
          raise Api::SyncError, "Error: #{response.code}"
        else
          set_sync_log(request_payload, response, response.code, 'success', 'successfully updated') if set_response_payload(response)
        end
      rescue HTTParty::Error, StandardError, SyncError => e
        set_sync_log(request_payload, response, response.code, 'failed', e.message)
      end
      response_payload
    end

    def update_erp_id
      if record.update_attributes(erp_id: get_erp_id)
        update_successful
      else
        update_failed
      end
    end
  end
end
