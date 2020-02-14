class Crm::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :name, type: String
  field :request_headers, type: String
  field :request_payload, type: String

  validate :validate_url
  validates :name, :domain, uniqueness: true, presence:true

  has_many :apis, dependent: :destroy

  def validate_url
    uri = URI.parse(self.domain)
    self.errors.add(:domain, 'has invalid url.') if !uri.is_a?(URI::HTTP) || uri.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:domain, 'has invalid url.')
  end
end
