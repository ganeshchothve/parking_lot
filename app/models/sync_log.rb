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
    if erp_model.resource_class == 'User'
      details = Api::UserDetailsSync.new(erp_model, record, parent_sync)
    elsif erp_model.resource_class == 'UserKyc'
      details = Api::UserKycDetailsSync.new(erp_model, record, parent_sync)
    elsif erp_model.resource_class == 'BookingDetail'
      details = Api::BookingDetailsSync.new(erp_model, record, parent_sync)
    elsif erp_model.resource_class == 'Receipt'
      details = Api::ReceiptDetailsSync.new(erp_model, record, parent_sync)
    elsif erp_model.resource_class == 'ChannelPartner'
      details = Api::ChannelPartnerDetailsSync.new(erp_model, record, parent_sync)
    end
    details.execute
  end
end
