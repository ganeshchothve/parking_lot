module Api
  class Sync
    attr_accessor :crm_api, :response_payload, :record, :url, :crm_id, :request_payload

    def initialize(crm_api, record)
      @crm_api = crm_api
      @record = record
      @request_payload = {}
      @response_payload = {}
      #      <domain>         / <YML-URL>
      # 'http://selldo.com/vi/booking_details' / 'user'
      @url = crm_api.base.domain + '/' + crm_api.path
    end

    def execute
      self.request_payload = set_request_payload
      response = get_response
      response
    end

    private


    def set_request_payload
      crm_api.set_request_payload(record)
    end


    def get_response
      response = RestClient::Request.execute(method: crm_api.request_type.to_sym, url: @url, payload: request_payload.to_json, headers: { 'Content-Type' => 'application/json' })
      case response.code
      when 400..511
        raise Api::SyncError, "#{response.try(:code)}: #{response.message}"
      else
        return response
      end
    rescue StandardError, SyncError => e
      set_sync_log(request_payload, response.as_json, response.try(:code) ? response.code : '404', false, e.message)
      puts e.message
    end
  end
end
