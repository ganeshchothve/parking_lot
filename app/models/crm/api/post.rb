class Crm::Api::Post < Crm::Api

  def execute record
    api_log = ApiLog.new(resource: record, crm_api: self)
    _request_payload = set_request_payload(record)
    _url = URI.join(base.domain, path)
    _request_header = get_request_header(record)
    uri = URI(_url)

    response = Net::HTTP.post_form(uri, _request_payload.merge({headers: _request_header}))

    case response
    when Net::HTTPSuccess
      res = process_response(response, record)
      update_api_log(api_log, _request_payload, _url, res, "Success")
      return {notice: "Object successfully pushed on CRM."}
    else
      update_api_log(api_log, _request_payload, _url, res, "Error", response.message)
      Rails.logger.error "-------- #{response.message} --------"
      return {alert: response.message}
    end

    rescue StandardError => e
      update_api_log(api_log, _request_payload, _url, res, "Error", e.message)
      Rails.logger.error "-------- #{e.message} --------"
      return {alert: e.message}
  end

  def process_response response, record
    if response.body == ''
      response = { error: 'Response is empty'}
    else
      response = JSON.parse(response.body)
    end
    response
  end

  def update_api_log api_log, request, request_url, response, status, message = nil
    api_log.update_attributes(request: request, request_url: request_url, response: response, status: status, message: message)
  end
end
