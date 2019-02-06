class ErpModel
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # Constants
  RESOURCE_CLASS = %w[User UserKyc Receipt BookingDetail ChannelPartner].freeze
  REQUEST_TYPE = [:json].freeze
  HTTP_VERB = %w[get post put patch].freeze
  DOMAIN = %w[https://gerasb-gerasb.cs57.force.com].freeze

  # Fields
  field :resource_class, type: String
  field :domain, type: String
  field :url, type: String
  field :request_type, type: Symbol, default: :json
  field :http_verb, type: String
  field :reference_key_name, type: String, default: :erp_id
  field :reference_key_location, type: String
  field :request_payload, type: String
  field :is_active, type: Boolean, default: :true
  field :action_name, type: String

  # Associations
  has_many :sync_logs

  # Validations
  validates :resource_class, inclusion: { in: RESOURCE_CLASS }
  validates :url, uniqueness: { scope: %i[domain resource_class] }
  validates :request_type, inclusion: { in: REQUEST_TYPE }
  validates :http_verb, inclusion: { in: HTTP_VERB }
  validates :domain, inclusion: { in: DOMAIN }
  validates :action_name, inclusion: { in: proc { ErpModel.allowed_action_names.collect { |x| x } } }
  validate :request_payload_format

  def self.allowed_action_names
    %w[create update]
  end

  def request_payload_format
    if request_payload.present?
      raise StandardError, 'Improper request payload format' unless SafeParser.new(request_payload).safe_load.is_a?(Hash)
    end
  rescue StandardError => e
    errors.add :request_payload, e.message
  end
end
