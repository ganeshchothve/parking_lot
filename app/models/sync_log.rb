class SyncLog
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # Fields
  field :request, type: Hash, default: {}
  field :response, type: Hash, default: {}
  field :response_code, type: Integer
  field :status, type: String, default: ''
  field :message, type: String, default: ''
  field :action, type: String, default: '' # Update/Create

  # Associations
  belongs_to :resource, polymorphic: true # , optional: true
  belongs_to :user_reference, class_name: 'User', inverse_of: :logs
  belongs_to :reference, class_name: 'SyncLog', optional: true
  has_many :sync_logs, class_name: 'SyncLog', foreign_key: 'reference_id'
  belongs_to :erp_model # TODO: remove optional true

  scope :filter_by_resource_id, ->(_resource_id) {where(resource_id: _resource_id) }
  scope :filter_by_erp_model_id, ->(_erp_model_id) {where(erp_model_id: _erp_model_id) }

  # validates :request, presence: true #ToDo SyncLog attributes

  def sync(erp_model, record)
    parent_sync = (self if self.action.present?)
    if Rails.env.production? || Rails.env.staging? || Rails.env.development?
      self.class.delay._sync(erp_model.id.to_s, record.id.to_s, parent_sync.try(:id).to_s)
    else
      Object.const_get(erp_model.resource_class).sync(erp_model, record, parent_sync)
    end
  end

  private

  def self._sync(erp_model_id, record_id, sync_log_id)
    erp_model = ErpModel.where(id: erp_model_id).first
    record = Object.const_get(erp_model.resource_class).where(id: record_id).first
    parent_sync_log = self.where(id: sync_log_id).first if sync_log_id.present?

    record.sync(erp_model, parent_sync_log)
  end
end
