class Gallery
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :assets, as: :assetable
  belongs_to :booking_portal_client, class_name: "Client"
end