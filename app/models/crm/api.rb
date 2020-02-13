class Crm::Api
  include Mongoid::Document
  include Mongoid::Timestamps

  REQUEST_TYPES = %w[get post]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :request_type, type: String
  field :response_decryption_key, type: String
  field :response_data_location, type: String

  belongs_to :base

  def execute record
    _request_payload = set_request_payload(record)
    _url = base.domain + '/' + path
    response = RestClient::Request.execute(method: request_type.to_sym, url: _url, payload: _request_payload.to_json, headers: { 'Content-Type' => 'application/json' })
      case response.code
      when 400..511
        Rails.logger.error "-------- #{response.message} --------"
      else
        process_response(response, record)
      end
    rescue StandardError => e
      Rails.logger.error "-------- #{e.message} --------"
  end

  def set_request_payload record
    erb = ERB.new(self.request_payload.gsub("\n\s", ''))
    SafeParser.new(erb.result(record.get_binding)).safe_load
  end
end
