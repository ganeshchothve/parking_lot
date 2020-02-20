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
  validates :resource_class, inclusion: { in: RESOURCE_CLASS }
  validates :response_data_location, format: {with: /\A[a-zA-Z0-9_..]*\z/}, allow_blank: true
  validates :request_type, uniqueness: {scope: [:resource_class, :base_id]}
  validates :path, :request_type, presence: true

  belongs_to :base

  def set_request_payload record
    _request_erb = ERB.new(request_payload.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _base_payload_erb = ERB.new(base.request_payload.gsub("\n\s", '')) rescue ERB.new("{}")
    _request_payload = SafeParser.new((_request_erb.result(record.get_binding))).safe_load rescue {}
    _base_request_payload = SafeParser.new((_base_payload_erb.result(record.get_binding))).safe_load rescue {}
    _request_payload.merge(_base_request_payload)
  end

  def validate_url
    uri = URI.parse(base.domain + "/" + path)
    self.errors.add(:path, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:path, 'has invalid url.')
  end
end
