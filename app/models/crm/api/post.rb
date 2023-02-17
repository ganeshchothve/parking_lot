class Crm::Api::Post < Crm::Api

  field :response_crm_id_location, type: String

  validates :response_crm_id_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true

  def execute record, user=nil
    _execute record, user, 'post'
  end

  def _execute record, user, method='post'
    api_log = ApiLog.new(resource: record, crm_api: self, booking_portal_client_id: self.booking_portal_client_id)
    _request_payload = set_request_payload(record) || {}

    _path_erb = ERB.new(path.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _path = _path_erb.result(record.get_binding) rescue ''

    _url = URI.join(base.domain, _path)
    _request_header = get_request_header(record) || {}
    set_access_token(user, _request_header)
    uri = URI(_url)

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri, _request_header)
    request.body = JSON.dump(_request_payload)
    response = https.request(request)
    # http.use_ssl = (uri.scheme == 'https')
    # response = http.send_request(method.upcase, uri.path, _request_payload.to_json, _request_header)
    case response
    when Net::HTTPSuccess
      res = process_response(response, record)
      update_api_log(api_log, _request_payload, _url, res, "Success", record)
      result = {notice: "Object successfully pushed on CRM."}
    else
      update_api_log(api_log, _request_payload, _url, (JSON.parse(response.body) rescue {}), "Error", record, response.message)
      Rails.logger.error "-------- #{response.message} --------"
      result = {alert: response.message}
    end

    result[:api_log] = api_log
    result

  rescue StandardError => e
    update_api_log(api_log, _request_payload, _url, (JSON.parse(response.try(:body)) rescue {}), "Error", record, e.message)
    Rails.logger.error "-------- #{e.message} --------"
    return {alert: e.message, api_log: api_log}
  end

  def process_response response, record
    if response.body == ''
      response = { error: 'Response is empty'}
    else
      response = JSON.parse(response.body)
      if response_crm_id_location.present?
        reference_id = response
        response_crm_id_location.split('.').each do |location|
          reference_id = reference_id[(location.match?(/\A\d\z/) ? location.to_i : location)] if reference_id.present?
        end
        record.update_external_ids({ reference_id: reference_id }, self.base_id) if reference_id.present?
      end
    end
    response
  end

  def update_api_log api_log, request, request_url, response, status, record, message = nil
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
      message: message,
      booking_portal_client: record.booking_portal_client
    )
  end
end
