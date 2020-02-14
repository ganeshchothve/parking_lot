class Crm::Api
  include Mongoid::Document
  include Mongoid::Timestamps

  REQUEST_TYPES = %w[get post]
  DEFAULT_REQUEST_HEADER = { 'Content-Type' => 'application/json' }
  RESOURCE_CLASS = %w[User UserKyc Receipt BookingDetail ChannelPartner]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :request_type, type: String
  field :response_decryption_key, type: String
  field :response_data_location, type: String

  validate :validate_url
  validates :resource_class, inclusion: { in: proc { RESOURCE_CLASS } }
  validates :response_data_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}
  validates :request_type, uniqueness: {scope: [:resource_class, :base_id]}

  belongs_to :base

  def execute record
    _request_payload = set_request_payload(record)
    _url = base.domain + '/' + path
    _request_header = DEFAULT_REQUEST_HEADER.merge(base.request_headers || {})
    response = RestClient::Request.execute(method: request_type.to_sym, url: _url, payload: _request_payload.to_json, headers: _request_header)
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
    SafeParser.new(erb.result(record.get_binding)).safe_load.merge(base.request_payload || {})
  end

  def validate_url
    uri = URI.parse(self.base.domain + "/" + self.path)
    self.errors.add(:path, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:path, 'has invalid url.')
  end
end
