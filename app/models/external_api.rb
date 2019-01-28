class ExternalApi
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :client_api, type: String, default: ''
  field :domain, type: String, default: ''
  field :private_key, type: String, default: ''
  field :encrypted_api_key, type: String, default: ''

  # Callbacks
  # before_validation :generate_keys # TODO :: call validation

  # Validations
  validates :domain, uniqueness: true, presence: true
  validates :private_key, uniqueness: true # , presence: true
  validates :encrypted_api_key, uniqueness: true # , presence: true
  validates :client_api, presence: true # , uniqueness: true

  # Methods
  def generate_keys
    api_key = SecureRandom.hex
    secret_key = SecureRandom.hex
    self.private_key = SecureRandom.hex # stored in database
    crypt = ActiveSupport::MessageEncryptor.new(secret_key) # encryption object
    encrypted_key = crypt.encrypt_and_sign(api_key.to_s) # encryption process
    crypt = ActiveSupport::MessageEncryptor.new(private_key)
    self.encrypted_api_key = crypt.encrypt_and_sign(encrypted_key.to_s)
    { api_key: api_key, secret_key: secret_key }
    # puts "\n\n\nApi_key : #{api_key} \n\n Secret key : #{secret_key} \n\n"
    # Send secret_key and api_key to External application as it is
  end
end
