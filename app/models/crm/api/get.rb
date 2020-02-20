class Crm::Api::Get < Crm::Api

  def execute resource
    _request_payload = set_request_payload(resource)
    _url = base.domain + '/' + path
    _base_header_erb = ERB.new(base.request_header.gsub("\n\s", '')) rescue ERB.new("{}")
    _base_request_header = SafeParser.new(_base_request_erb.result(resource.get_binding)).safe_load rescue {}
    _request_header = DEFAULT_REQUEST_HEADER.merge(_base_request_header)
    uri = URI(_url)
    uri.query = URI.encode_www_form(_request_payload.merge({headers: _request_header}))
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPSuccess
      process_response(response.body, resource)
    else
      Rails.logger.error "-------- #{response.message} --------"
    end
    rescue StandardError => e
      Rails.logger.error "-------- #{e.message} --------"
  end

  def process_response(response, resource)
    resp = parse_json(response)
    html = Presenters::JsonPresenter.json_to_html(resp, resource.class)
  end

  def parse_json json
    json_response = JSON.parse(json)
    response_data_location.split('.').each do |location|
      json_response = json_response[location]
    end if response_data_location.present?
    obj = JWT.decode(json_response, response_decryption_key)[0] if response_decryption_key.present?
    obj.compact
  end
end
