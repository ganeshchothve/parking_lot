class Gallery
  include Mongoid::Document
  include Mongoid::Timestamps

  # Add different types of documents which are uploaded on gallery
  DOCUMENT_TYPES = []

  has_many :assets, as: :assetable
  belongs_to :booking_portal_client, class_name: "Client"
end
