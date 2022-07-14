class ExternalApi
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :client_api, type: String, default: ''
  field :domain, type: String, default: ''
  field :api_key, type: String, default: ''

  # Callbacks
  # before_validation :generate_key # TODO :: call validation
  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  # Validations
  validates :domain, uniqueness: true, presence: true
  validates :api_key, uniqueness: true # , presence: true
  validates :client_api, presence: true # , uniqueness: true

  # private
  # Methods
  def generate_key
    self.api_key = SecureRandom.hex # stored in database
    save
    api_key # send to external api
  end
end
