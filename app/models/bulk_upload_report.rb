class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps

  DOCUMENT_TYPES = %w(receipts_status_update user_requests_status_update project_units_update inventory_upload)

  field :total_rows, type: Integer, default: 0
  field :success_count, type: Integer, default: 0
  field :failure_count, type: Integer, default: 0

  belongs_to :uploaded_by, class_name: 'User'
  belongs_to :client
  has_one :asset, as: :assetable
  embeds_many :upload_errors

  validate :asset_presence

  accepts_nested_attributes_for :asset

  private

  def asset_presence
    self.errors.add :base, 'File cannot be blank' if self.asset.try(:file).blank?
  end
end
