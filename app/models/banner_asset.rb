class BannerAsset
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  mount_uploader :banner_image, PublicAssetUploader
  mount_uploader :mobile_banner_image, PublicAssetUploader

  field :file_size, type: Integer
  field :mobile_file_size, type: Integer
  field :file_name, type: String
  field :mobile_file_name, type: String #image file used for mobile devices
  field :url, type: String
  field :publish, type: Boolean, default: true

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :uploaded_by, class_name: 'User'

  scope :filter_by_publish, ->{ where(publish: true) }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }

end
