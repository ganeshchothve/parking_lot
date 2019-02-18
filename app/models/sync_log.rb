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
  belongs_to :erp_model, optional: true # TODO: remove optional true

  # validates :request, presence: true #ToDo SyncLog attributes

  def sync(erp_model, record)
    parent_sync = (self if self.action.present?)
    if Rails.env.production? || Rails.env.staging?
      Object.const_get(erp_model.resource_class).delay.sync(erp_model, record, parent_sync)
    else
      Object.const_get(erp_model.resource_class).sync(erp_model, record, parent_sync)
    end
  end
end
