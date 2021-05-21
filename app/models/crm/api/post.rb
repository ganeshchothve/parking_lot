class Crm::Api::Post < Crm::Api

  field :response_crm_id_location, type: String

  validates :response_crm_id_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true

  def execute record
    api_log = ApiLog.new(resource: record, crm_api: self)
    _request_payload = set_request_payload(record) || {}
    _url = URI.join(base.domain, path)
    _request_header = get_request_header(record) || {}
    _request_header['Authorization'] = "Bearer #{get_access_token}" if base.oauth2_authentication?
    uri = URI(_url)

    response = Net::HTTP.post(uri, _request_payload.to_json, _request_header)
    case response
    when Net::HTTPSuccess
      res = process_response(response, record)
      update_api_log(api_log, _request_payload, _url, res, "Success")
      return {notice: "Object successfully pushed on CRM."}
    else
      update_api_log(api_log, _request_payload, _url, (JSON.parse(response.body) rescue {}), "Error", response.message)
      Rails.logger.error "-------- #{response.message} --------"
      return {alert: response.message}
    end

  rescue StandardError => e
    update_api_log(api_log, _request_payload, _url, (JSON.parse(response.try(:body)) rescue {}), "Error", e.message)
    Rails.logger.error "-------- #{e.message} --------"
    return {alert: e.message}
  end

  def get_access_token
    sfdc_credentials = ENV_CONFIG['sfdc'] || {}
    if sfdc_credentials.present?
      uri = URI(base.domain)
      uri.path = "/#{path}".squeeze('/')
      host = uri.host
      sfdc_credentials['api_version'] = '41.0'
      sfdc_credentials['instance_url'] = base.domain
      sfdc_credentials['host'] = host
      client = Restforce.new(sfdc_credentials.symbolize_keys)
      begin
        response = client.authenticate!
        response.dig("access_token")
      rescue Restforce::AuthenticationError => e
        Rails.logger.error "[Crm::Api::Post] Restforce authentication error: #{e.message}"
      end
    else
      Rails.logger.error "[Crm::Api::Post] OAuth credentials not found"
    end
  end

  def process_response response, record
    if response.body == ''
      response = { error: 'Response is empty'}
    else
      response = JSON.parse(response.body)
      if response_crm_id_location.present?
        reference_id = response
        response_crm_id_location.split('.').each do |location|
          reference_id = reference_id[(location.match?(/\A\d\z/) ? location.to_i : location)]
        end
        record.update_external_ids({ reference_id: reference_id }, self.base_id) if reference_id.present?
      end
    end
    response
  end

  def update_api_log api_log, request, request_url, response, status, message = nil
    req = request.is_a?(Hash) ? [request] : request
    resp = if response.is_a?(Hash)
             response_type = 'Hash'
             [response]
           else
             response_type = 'Array'
             response
           end

    api_log.update_attributes(
      request: req,
      request_url: request_url,
      response: resp,
      response_type: response_type,
      status: status,
      message: message
    )
  end
end
