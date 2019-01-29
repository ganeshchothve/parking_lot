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
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :user_reference, class_name: 'User', foreign_key: 'user_id'
  belongs_to :reference, class_name: 'SyncLog', optional: true
  has_many :sync_logs, class_name: 'SyncLog', foreign_key: 'reference_id'

  # validates :request, presence: true #ToDo SyncLog attributes
end
