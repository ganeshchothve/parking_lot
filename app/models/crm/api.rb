class Crm::Api
  include Mongoid::Document

  REQUEST_TYPES = %w[get post]

  field :resource_class, type: String
  field :path, type: String
  field :request_payload, type: String
  field :request_type, type: String

  belongs_to :base

  def execute record
    response = ::Api::Sync.new(self, record).execute
  end

  def set_request_payload(record)
    erb = ERB.new(self.request_payload.gsub("\n\s", ''))
    SafeParser.new(erb.result(binding)).safe_load
  end
end
