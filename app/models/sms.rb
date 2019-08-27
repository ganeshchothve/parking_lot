class Sms
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  STATUS = %w(received untracked scheduled sent failed)

  # Scopes
  scope :filter_by_to, ->(phone) { where(to: phone) }
  scope :filter_by_body, ->(body) { where(body: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, ->(date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, ->(status) { where(status: status) }

  # Fields
  field :to, type: Array
  field :body, type: String
  field :sent_on, type: DateTime
  field :status, type: String, default: "scheduled"

  belongs_to :sms_template, class_name: 'Template::SmsTemplate', optional: true

  # Associations
  belongs_to :recipient, class_name: "User", inverse_of: :received_smses, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :booking_portal_client, class_name: "Client"

  validates :body, presence: true, if: Proc.new{ |model| model.sms_template_id.blank? }
  validates :triggered_by_id, :recipient_id, presence: true
  validates_inclusion_of :status, in: STATUS

  enable_audit audit_fields: [:body, :sent_on], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::SmsTemplate"}]

  default_scope -> {desc(:created_at)}

end
