module Api
  class Syncc
    attr_accessor :synclog, :response_payload, :record, :parent_sync, :erp_model, :url, :erp_id, :request_payload

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
      self.request_payload = set_request_payload
      get_response
      if response_payload['returnCode'].present?
        response_payload['returnCode'] ? nil : update_erp_id if erp_model.action_name == 'create'
      end
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
      elsif request_payload[erp_model.reference_key_name].present? && (request_payload[erp_model.reference_key_name] != get_erp_id)
        raise Api::SyncError, "#{erp_model.resource_class} #{erp_model.reference_key_name} in request and response must be the same"
      else
        true
      end
    end

    def set_request_payload
      erb = ERB.new(erp_model.request_payload)
      SafeParser.new(erb.result(binding)).safe_load
    end

    def set_sync_log(request, response, response_code, status, message)
      response = JSON.parse(response) if response.is_a?(RestClient::Response)
      synclog.update_attributes(request: request, response: response, response_code: response_code, status: status ? 'successful' : 'failed', message: message, action: erp_model.action_name, resource: record, user_reference: record_user, reference: parent_sync)
    end

    def set_response_payload(response)
      byebug
      raise StandardError, 'JSON Parse Error' unless self.response_payload = JSON.parse(response)
      #response_payload = response[:body][erp_model.resource_class]
      response_payload.present? ? validate_erp_id : (raise StandardError, 'Response is blank')
    end

    def get_erp_id
      response = response_payload
      erp_model.reference_key_location.split(',').each do |key|
        # can be ", " according to format
        response = response[key] if response[key].present?
      end
      erp_id = response['RrecordId']
    end

    def get_response
      response = RestClient::Request.execute(method: erp_model.http_verb.to_sym, url: @url, payload: request_payload.to_json, headers: { 'Content-Type' => 'application/json' })
      case response.code
      when 400..511
        raise Api::SyncError, "#{response.try(:code)}: #{response.message}"
      else
        set_sync_log(request_payload, response, response.code, response_payload['returnCode'].zero?, response_payload['message']) if set_response_payload(response)
        end
    rescue HTTParty::Error, StandardError, SyncError => e
      set_sync_log(request_payload, response.as_json, response.try(:code) ? response.code : '404', false, e.message)
      puts e.message
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
