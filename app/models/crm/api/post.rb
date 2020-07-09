class Crm::Api::Post < Crm::Api

  field :response_crm_id_location, type: String

  validates :response_crm_id_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true

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
      if response_crm_id_location.present?
        reference_id = response
        response_crm_id_location.split('.').each do |location|
          reference_id = reference_id[location]
        end
        record.update_reference_id(reference_id, self.id) if reference_id.present?
      end
    end
    response
  end

  def update_api_log api_log, request, request_url, response, status, message = nil
    api_log.update_attributes(request: request, request_url: request_url, response: response, status: status, message: message)
  end
end
