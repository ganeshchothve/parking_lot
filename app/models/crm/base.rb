class Crm::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :name, type: String
  field :request_headers, type: String
  field :request_payload, type: String
  field :api_key, type: String

  validate :validate_url
  validates :domain, uniqueness: true, presence:true
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates_format_of :domain, :with => /\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/

  has_many :apis, dependent: :destroy

  def validate_url
    uri = URI.parse(self.domain)
    self.errors.add(:domain, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:domain, 'has invalid url.')
  end

  def generate_api_key!
    api_key ||= SecureRandom.hex
    save
  end

  def regenerate_api_key!
    api_key = SecureRandom.hex
    save
  end

  def self.active_apis(resource)
    _crm_ids = resource.third_party_references.distinct(:crm_id)
    Crm::Api.where(resource_class: resource.class, is_active: true).where({"$or": [{_type: 'Crm::Api::Get', base_id: {"$in": _crm_ids}}, {_type: 'Crm::Api::Post'}]})
  end
end
