module Api
  class Syncc
    attr_accessor :synclog, :response_payload, :record, :parent_sync, :erp_model, :url, :erp_id, :request_payload

    def initialize(erp_model, record, parent_sync_record = nil)
      @erp_model = erp_model
      @parent_sync = parent_sync_record
      @synclog = SyncLog.new(erp_model: erp_model)
      @record = record
      @request_payload = {}
      @response_payload = {}
      #      <domain>         / <YML-URL>
      # 'http://selldo.com/vi/booking_details' / 'user'
      @url = erp_model.domain + '/' + erp_model.url
    end

    def execute
      self.request_payload = set_request_payload
      erp_id = get_response
      if erp_id.present?
        if erp_model.action_name == 'create'
          record.update_erp_id(erp_id, erp_model.domain)
          puts "#{erp_model.resource_class} successfully created with erp_id: #{erp_id}"
        else
          puts "#{erp_model.resource_class} with erp_id: #{erp_id} updated successfully"
        end
      end
    end

    private

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
      erp_model.set_request_payload(record)
    end

    def set_sync_log(request, response, response_code, status, message)
      if response == ''
        response = { error: 'Response is empty'}
      else
        response = JSON.parse(response) if response.is_a?(RestClient::Response)
      end
      synclog.update_attributes(request: request, response: response, response_code: response_code, status: status ? 'successful' : 'failed', message: message, action: erp_model.action_name, resource: record, user_reference: record_user, reference: parent_sync)
    end

    def set_response_payload(response)
      raise StandardError, 'JSON Parse Error' unless self.response_payload = JSON.parse(response)
      #response_payload = response[:body][erp_model.resource_class]
      response_payload.present? ? validate_erp_id : (raise StandardError, 'Response is blank')
    end

    def get_erp_id
      _erp_id = response_payload
      erp_model.reference_key_location.split(',').each do |key|
        # can be ", " according to format
        _erp_id = response[key] if _erp_id[key].present?
      end
      _erp_id[erp_model.reference_key_name]
    end

    def get_response
      response = RestClient::Request.execute(method: erp_model.http_verb.to_sym, url: @url, payload: request_payload.to_json, headers: { 'Content-Type' => 'application/json' })
      case response.code
      when 400..511
        raise Api::SyncError, "#{response.try(:code)}: #{response.message}"
      else
        set_sync_log(request_payload, response, response.code, response_payload['returnCode'].try(:zero?) || true, response_payload['message']) if set_response_payload(response)
      end
      get_erp_id
    rescue StandardError, SyncError => e
      set_sync_log(request_payload, response.as_json, response.try(:code) ? response.code : '404', false, e.message)
      puts e.message
    end
  end
end
