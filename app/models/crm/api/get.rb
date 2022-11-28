class Crm::Api::Get < Crm::Api

  field :response_data_location, type: String
  field :filter_hash, type: String
  field :response_decryption_key, type: String

  validates :response_data_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true

  def execute resource, user
    _request_payload = set_request_payload(resource)

    _path_erb = ERB.new(path.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _path = _path_erb.result(resource.get_binding) rescue ''

    _url = URI.join(base.domain, _path)
    _request_header = get_request_header(resource)
    api.set_access_token(user, _request_header)
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
    obj = json_response
    response_data_location.split('.').each do |location|
      json_response = json_response[location]
    end if response_data_location.present?
    obj = JWT.decode(json_response, response_decryption_key)[0] if response_decryption_key.present?
    if filter_hash.present?
      _filter_hash = process_filter_hash
      obj = JsonUtil.filter(_filter_hash, obj)
    end
    obj
  end

  def process_filter_hash
    SafeParser.new(filter_hash).safe_load rescue {}
  end
end
