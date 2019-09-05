class Asset
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  mount_uploader :file, AssetUploader

  field :file_size, type: Integer
  field :file_name, type: String
  field :asset_type, type: String
  field :original_filename, type: String
  # type or purpose of the document will be stored here. for eg. - photo_identity proof
  # types of document can be different for different assetables and will stored in DOCUMENT_TYPES in respective models.
  field :document_type, type: String

  belongs_to :assetable, polymorphic: true

  scope :filter_by_document_type, ->(type) { where(document_type: type) }

  validates :file_name, uniqueness: { scope: [:assetable_type, :assetable_id] }
  validates :asset_type, uniqueness: { scope: [:assetable_type, :assetable_id] }, if: proc{|asset| asset.asset_type == 'floor_plan' }

end
