class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps

  DOCUMENT_TYPES = %w(receipts_status_update user_requests_status_update project_units_update inventory_upload leads receipts)# channel_partners channel_partner_manager_change)
  PROJECT_SCOPED = %w(leads receipts)

  field :total_rows, type: Integer, default: 0
  field :success_count, type: Integer, default: 0
  field :failure_count, type: Integer, default: 0

  belongs_to :uploaded_by, class_name: 'User'
  belongs_to :client
  belongs_to :project, optional: true
  has_one :asset, as: :assetable
  embeds_many :upload_errors

  validate :asset_presence

  accepts_nested_attributes_for :asset

  private

  def asset_presence
    self.errors.add :base, 'File cannot be blank' if self.asset.try(:file).blank?
    self.errors.add :project_id, 'cannot be blank' if self.asset.try(:document_type).try(:in?, PROJECT_SCOPED)
  end
end
