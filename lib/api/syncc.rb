module Api
  class Syncc
    attr_accessor :synclog, :path, :request_payload, :response_payload, :external_api, :record, :parent_sync

    def initialize(client_api, record, parent_sync_record = nil)
      @path = YAML.load_file("#{Rails.root}/config/#{client_api}.api_sync.yml")
      @external_api = ExternalApi.where(client_api: client_api).first
      # raise exception if YML file is missing.
      # raise exception if external_api is missing.
      parent_sync = parent_sync_record
      @synclog = SyncLog.new
      @request_payload = {}
      @response_payload = {}
      @record = record
    end

    def get_url
      #      <domain>         / <YML-URL>
      # 'http://selldo.com/vi/booking_details' / 'user'
      external_api.domain + '/' + path[name]
    end

    def update_successful
      puts "#{name} erp-id updated successfully"
    end

    def update_failed
      raise Api::SyncError, "Could not update #{name} erp-id"
    rescue SyncError => e
      puts e.message
    end

    def validate_erp_id
      if response_payload[:erp_id].blank?
        raise Api::SyncError, "#{name} erp-id is required"
      elsif request_payload[:erp_id].present? && (request_payload[:erp_id] != response_payload[:erp_id])
        raise Api::SyncError, "#{name} erp-id in request and response must be the same"
      else
        true
      end
    end

    private

    def set_request_payload
      DATA_FIELDS.each do |key|
        request_payload.store(key, record[key]) if record[key].present?
      end
      request_payload
    end

    def set_sync_log(request, response, response_code, status, message, http_verb)
      action = if http_verb == 'patch'
                 'update'
               else
                 'create'
               end
      synclog.update_attributes(request: request, response: response, response_code: response_code, status: status, message: message, action: action, resource: record, user_reference: record_user, reference: parent_sync)
    end

    def set_response_payload(response)
      response_payload = response[:body][name]
      validate_erp_id
    end

    def get_response(http_verb)
      begin
        body = { body: {} }
        body[:body][name] = request_payload
        if http_verb == 'post'
          response = HTTParty.post(@url.to_str, body.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
        elsif http_verb == 'patch'
          response = HTTParty.patch(@url.to_str, body.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
        end
        case response.code # Check
        when 400..511
          raise Api::SyncError, "Error: #{response.code}"
        else
          set_sync_log(request_payload, response, response.code, 'success', 'successfully updated', http_verb) if set_response_payload(response)
        end
      rescue HTTParty::Error, StandardError, SyncError => e
        set_sync_log(request_payload, response, response.code, 'failed', e.message, http_verb)
      end
      response_payload
    end

    def on_create
      set_request_payload
      request_payload.store(:erp_id, '')
      get_response(:post)
      update_erp_id
    end

    def on_update
      set_request_payload
      request_payload.store(:erp_id, record.erp_id)
      get_response(:patch)
    end

    def update_erp_id
      if record.update_attributes(erp_id: response_payload[:erp_id])
        update_successful
      else
        update_failed
      end
    end
  end
end
