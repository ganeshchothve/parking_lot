class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :total_rows, type: Integer, default: 0
  field :success_count, type: Integer, default: 0
  field :failure_count, type: Integer, default: 0

  belongs_to :uploaded_by, class_name: 'User'
  embeds_many :upload_errors
  has_one :asset, as: :assetable

  validate :asset_presence

  accepts_nested_attributes_for :asset

  private
  def asset_presence
    self.errors.add :base, 'File cannot be blank' if !self.asset.file.present?
  end
end