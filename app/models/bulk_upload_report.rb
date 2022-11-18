class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps
  extend DocumentsConcern

  DOCUMENT_TYPES = %w(receipts_status_update user_requests_status_update project_units_update inventory_upload leads receipts channel_partners time_slots_update channel_partner_manager_change channel_partner_user)
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

  alias_attribute :booking_portal_client_id, :client_id
  private

  def asset_presence
    self.errors.add :base, 'File cannot be blank' if self.asset.try(:file).blank?
    self.errors.add :project_id, 'cannot be blank' if self.asset.try(:document_type).try(:in?, PROJECT_SCOPED) && self.project_id.blank?
  end

  class << self

    def user_based_scope user, params={}
      if user.role?(:superadmin)
        custom_scope = {  }
      else
        custom_scope = {  }
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end

  end
end
