class ErpModel
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

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
  validates :resource_class, inclusion: { in: %w[User UserKyc Receipt BookingDetail ChannelPartner] }
  validates :url, uniqueness: { scope: %i[domain resource_class] }
  validates :request_type, inclusion: { in: [:json] }
  validates :http_verb, inclusion: { in: %w[get put post patch] }
  validates :action_name, inclusion: { in: %w[create update] }
  # validate :resource_class_present?
  # validate :domain_present?
  validate :request_payload_format

  # def available_resource_classes
  #   return an array from yml file
  #   validates_inclusion in this array
  # end

  # def domain_present?
  #   @external_api = ExternalApi.where(domain: domain).first
  #   if @external_api.present?
  #     @yaml_object = YAML.load_file("#{Rails.root}/config/#{@external_api.client_api}.api_sync.yml")
  #     # raise exception if YML file is missing.
  #     errors.add :resource_class, 'Not present in yml file' if @yaml_object['domain'].present?
  #   else
  #     errors.add :domain, 'Not registered with application'
  #   end
  # end

  def request_payload_format
    if request_payload.present?
      raise StandardError, 'Improper request payload format' unless SafeParser.new(request_payload).safe_load.is_a?(Hash)
    end
  rescue StandardError => e
    errors.add :request_payload, e.message
  end

  # def resource_class_present?
  #   @external_api = ExternalApi.where(domain: domain).first
  #   if @external_api.present?
  #     @yaml_object = YAML.load_file("#{Rails.root}/config/#{@external_api.client_api}.api_sync.yml")
  #     # raise exception if YML file is missing.
  #     errors.add :resource_class, 'Not present in yml file' if @yaml_object['url'][resource_class.to_s].present?
  #   else
  #     errors.add :domain, 'Not registered with application'
  #   end
  # end
end
