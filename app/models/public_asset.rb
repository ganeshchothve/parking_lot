class PublicAsset
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  mount_uploader :file, PublicAssetUploader

  field :file_size, type: Integer
  field :file_name, type: String
  field :asset_type, type: String
  field :original_filename, type: String
  # type or purpose of the document will be stored here. for eg. - photo_identity proof
  # types of document can be different for different assetables and will stored in DOCUMENT_TYPES in respective models.
  field :document_type, type: String

  belongs_to :public_assetable, polymorphic: true

  scope :filter_by_document_type, ->(type) { where(document_type: type) }

  validates :file_name, uniqueness: { scope: [:document_type, :public_assetable_id], message: '^File with this name is already uploaded' }
  validates :asset_type, uniqueness: { scope: [:public_assetable_type, :public_assetable_id] }, if: proc{|asset| asset.asset_type == 'floor_plan' }
  validate :validate_content, on: :create
  #before_destroy :check_document_validation_on_receipt

  def validate_content
    _file = file.file
    file_name = _file.try(:original_filename)
    if _file && file_name.present?
      self.errors.add(:base, 'Invalid file name/type (The filename should not have more than one dot (.))') if file_name.split('.').length > 2
      self.errors.add(:base, 'File without name provided') if file_name.split('.')[0].blank?
      file_meta = MimeMagic.by_path(file.path) rescue nil
      self.errors.add(:base, 'Invalid file (you can only upload jpg|png|jpeg|pdf|csv files)') if ( file_meta.nil? || %w[png jpg jpeg pdf PNG JPG PDF JPEG csv].exclude?(file_meta.subtype) )
    end
  end
end
