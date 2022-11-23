class Crm::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  OAUTH_TYPES = ["salesforce", "kylas"]

  field :domain, type: String
  field :name, type: String
  field :request_headers, type: String
  field :request_payload, type: String
  field :api_key, type: String
  field :oauth2_authentication, type: Boolean
  field :oauth_type, type: String

  validate :validate_url
  validates :domain, uniqueness: true, presence:true
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates_format_of :domain, :with => /\A(http|https):\/\/[a-z0-9-]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/
  validate :validate_user_role

  has_many :apis, dependent: :destroy
  belongs_to :user, class_name: 'User'
  belongs_to :booking_portal_client, class_name: 'Client'

  def validate_user_role
    self.errors.add(:base, "User role should be administrator") unless self.user.role?('admin')
  end

  def validate_url
    uri = URI.parse(self.domain)
    self.errors.add(:domain, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:domain, 'has invalid url.')
  end

  def generate_api_key!
    self.api_key ||= SecureRandom.hex
    save
  end

  def regenerate_api_key!
    self.api_key = SecureRandom.hex
    save
  end

  def self.active_apis(resource)
    _crm_ids = resource.third_party_references.distinct(:crm_id)
    Crm::Api.where(booking_portal_client_id: resource.booking_portal_client.try(:id), resource_class: resource.class, is_active: true).where({"$or": [{_type: 'Crm::Api::Get', base_id: {"$in": _crm_ids}}, {_type: 'Crm::Api::Post'}]})
  end
end
