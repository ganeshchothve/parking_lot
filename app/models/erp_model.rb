class ErpModel
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # Constants
  RESOURCE_CLASS = %w[User UserKyc Receipt BookingDetail ChannelPartner]
  REQUEST_TYPE = [:json]
  HTTP_VERB = %w[get post put patch]
  # DOMAIN = %w[http://staging.sell.do]
  ACTION_NAME = %w(create update)

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
  # validates :domain, inclusion: { in: DOMAIN }
  validates :action_name, inclusion: { in: ACTION_NAME  }
  validate :request_payload_format

  scope :active, ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false)}

  def request_payload_format
    if request_payload.present?
      begin
        raise StandardError, 'Improper request payload format' unless SafeParser.new(request_payload.gsub("\n\s", '')).safe_load.is_a?(Hash)
      rescue StandardError => e
        errors.add :request_payload, e.message
      end
    end
  end

  def set_request_payload(record)
    erb = ERB.new(self.request_payload.gsub("\n\s", ''))
    SafeParser.new(erb.result(binding)).safe_load
  end
end
