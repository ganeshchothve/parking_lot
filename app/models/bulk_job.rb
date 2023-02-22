require 'autoinc'
class BulkJob
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include Mongoid::Autoinc
  extend FilterByCriteria

  ENTITY_TYPES = %w[Lead SiteVisit User].freeze
  STATUSES = %w[queued in_progress completed partially_completed failed].freeze
  OPERATION_TYPES = %w[create update].freeze

  field :entity_type, type: String
  field :operation_type, type: String
  field :bulk_job_id, type: Integer # UI index pupose
  field :status, type: String, default: 'queued'
  field :payload, type: Hash, default: {} # params from UI
  field :background_job_id, type: String # Sidekiq job id
  field :total_records, type: Integer, default: 0
  field :executed_records, type: Integer, default: 0
  field :entities_filter_payload, type: Hash, default: {} # filter payload for fetch data from kylas
  field :required_fields, type: Array # required fields for fetch data from kylas
  field :failed_response, type: Array, default: []
  field :execute_worker, type: String # worker name

  increments :bulk_job_id, seed: 1 # auto increment

  mount_uploader :success_file, DocUploader
  mount_uploader :failure_file, DocUploader

  has_many :records, dependent: :destroy
  belongs_to :creator, class_name: 'User'
  belongs_to :booking_portal_client, class_name: 'Client'

  # Scopes
  scope :filter_by_bulk_job_id, ->(bulk_job_id) { where(bulk_job_id: bulk_job_id) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_entity_type, ->(entity_type) { where(entity_type: entity_type) }

  # class methods
  class << self
    def user_based_scope user, params={}
      custom_scope = {}
      if user.role.in?(%w(admin sales))
        custom_scope = {  }
      elsif user.role.in?(%w(superadmin))
        custom_scope = {  }
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end
  end
end
