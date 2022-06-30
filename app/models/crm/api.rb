class Crm::Api
  include Mongoid::Document
  include Mongoid::Timestamps
  include JSONStringParser

  DEFAULT_REQUEST_HEADER = { 'Content-Type' => 'application/json' }
  RESOURCE_CLASS = %w[User UserKyc Receipt BookingDetail ChannelPartner Lead SiteVisit FundAccount Invoice]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :is_active, type: Boolean, default: true
  field :event, type: String

  validate :validate_url
  validates :resource_class, inclusion: { in: RESOURCE_CLASS }
  #validates :_type, uniqueness: {scope: [:resource_class, :base_id]}
  validates :path, :_type, presence: true

  default_scope -> { where(event: {'$in': ['', nil]}) }

  belongs_to :base

  def set_request_payload record
    _request_erb = ERB.new(request_payload.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _base_payload_erb = ERB.new(base.request_payload.gsub("\n\s", '')) rescue ERB.new("{}")
    _request_payload = SafeParser.new(_request_erb.result(record.get_binding)).safe_load rescue {}
    _base_request_payload = SafeParser.new(_base_payload_erb.result(record.get_binding)).safe_load rescue {}
    _request_payload.merge(_base_request_payload)
    recursive_json_string_parser(_request_payload)
  end

  def validate_url
    uri = URI.join(base.domain, path.gsub(/<%.*%>/, ''))
    self.errors.add(:path, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:path, 'has invalid url.')
  end

  def get_request_header record
    _base_header_erb = ERB.new(base.request_headers.gsub("\n\s", '')) rescue ERB.new("{}")
    _base_request_header = SafeParser.new(_base_header_erb.result(record.get_binding)).safe_load rescue {}
    _request_header = DEFAULT_REQUEST_HEADER.merge(_base_request_header)
  end

  def self.execute(api_id, record_id)
    api = where(id: api_id).first
    if api
      record = Object.const_get(api.resource_class).where(id: record_id).first
      api.execute(record)
    end
  end
end
