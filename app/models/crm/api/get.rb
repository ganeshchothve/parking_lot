class Crm::Api::Get < Crm::Api

  def process_response(response, record)
    resp = parse_json(response)
    html = Presenters::JsonPresenter.json_to_html(resp, record.class)
  end

  def parse_json json
    json_response = JSON.parse(json)
    response_data_location.split('.').each do |location|
      json_response = json_response[location]
    end
    obj = JWT.decode(json_response, response_decryption_key)[0]
    obj.compact
  end
end
