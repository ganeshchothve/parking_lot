class Crm::Api::Post < Crm::Api

  def execute record
    _request_payload = set_request_payload(record)
    _url = base.domain + '/' + path
    _request_header = DEFAULT_REQUEST_HEADER.merge(base.request_headers || {})
    uri = URI(_url)
    response = Net::HTTP.post_form(uri, _request_payload.merge({headers: _request_header}))
    case response
    when Net::HTTPSuccess
      process_response(response.body, record)
    else
      Rails.logger.error "-------- #{response.message} --------"
    end
    rescue StandardError => e
      Rails.logger.error "-------- #{e.message} --------"
  end

  def process_request
    puts "post"
  end
end
