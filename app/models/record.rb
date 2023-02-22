class Record
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  STATUSES = %w[queued in_progress completed failed].freeze

  field :entity_id, type: String
  field :partner_id, type: String
  field :status, type: String, default: 'queued'
  field :error_message, type: String
  field :entity_payload, type: Hash, default: {}


  belongs_to :bulk_job
  belongs_to :booking_portal_client, class_name: 'Client'
end
