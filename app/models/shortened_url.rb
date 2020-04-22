class ShortenedUrl
  include Mongoid::Document
  include Mongoid::Timestamps

  before_validation :generate_shortened_url

  field :original_url, type: String
  field :code, type: String

  validates :original_url, :code, uniqueness: true, presence: true

  def self.clean_url(url)
    url = url.to_s.strip
    URI.parse(url).normalize
  end

  def generate_shortened_url
    begin
      self.code = SecureRandom.hex(3)
    end while self.class.where(code: self.code).present?
  end
end