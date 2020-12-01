class Crm::Api
  include Mongoid::Document
  include Mongoid::Timestamps

  DEFAULT_REQUEST_HEADER = { 'Content-Type' => 'application/json' }
  RESOURCE_CLASS = %w[User UserKyc Receipt BookingDetail ChannelPartner]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :is_active, type: Boolean, default: true

  validate :validate_url
  validates :resource_class, inclusion: { in: RESOURCE_CLASS }
  validates :_type, uniqueness: {scope: [:resource_class, :base_id]}
  validates :path, :_type, presence: true

  belongs_to :base

  def set_request_payload record
    _request_erb = ERB.new(request_payload.gsub("\n\s", '')) rescue ERB.new("Hash.new")
    _base_payload_erb = ERB.new(base.request_payload.gsub("\n\s", '')) rescue ERB.new("{}")
    _request_payload = SafeParser.new(_request_erb.result(record.get_binding)).safe_load rescue {}
    _base_request_payload = SafeParser.new(_base_payload_erb.result(record.get_binding)).safe_load rescue {}
    _request_payload.merge(_base_request_payload)
    safe_parse(_request_payload)
  end

  def safe_parse(data)
    res = data
    case (res ||= data)
    when Hash
      res.each do |key, value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        res[key] = ((_value.is_a?(Hash) || _value.is_a?(Array)) ? safe_parse(_value) : value)
      end
      res
    when Array
      res.map! do |value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        (_value.is_a?(Hash) || _value.is_a?(Array)) ? safe_parse(_value) : value
      end
      Array.new.push(*res)
    else
      res
    end
  end

  def validate_url
    uri = URI.join(base.domain, path)
    self.errors.add(:path, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:path, 'has invalid url.')
  end

  def get_request_header record
    _base_header_erb = ERB.new(base.request_headers.gsub("\n\s", '')) rescue ERB.new("{}")
    _base_request_header = SafeParser.new(_base_header_erb.result(record.get_binding)).safe_load rescue {}
    _request_header = DEFAULT_REQUEST_HEADER.merge(_base_request_header)
  end
end
