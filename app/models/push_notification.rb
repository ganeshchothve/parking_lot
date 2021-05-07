class PushNotification
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # now handled only sent and failed later will add callback
  STATUSES = %w[queued failed sent]

  field :title, type: String
  field :content, type: String
  field :url, type: String
  field :status, type: String, default: 'queued' # queued, failed, sent, delivered, read, received
  field :user_notification_tokens, type: Array, default: []
  field :response, type: String # for queued, send, delivered, read message
  field :vendor, type: String, default: 'Firebase'
  field :sent_on, type: DateTime
  field :role, type: String

  scope :filter_by_content, -> (content) { where(content: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, -> (date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, -> (status) { where(status: status) }

  # Associations
  belongs_to :recipient, class_name: 'User', inverse_of: :received_notifications, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true, class_name: 'User'
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :notification_template, class_name: 'Template::NotificationTemplate', optional: true

  # Validations
  # validates :content, presence: true
  validate :role_or_triggered_by_present?
  validates_inclusion_of :status, in: STATUSES

  # enable_audit audit_fields: [:title, :content, :created_at], reference_ids_without_associations: [{ field: 'notification_template_id', klass: 'Template::NotificationTemplate' }]

  default_scope -> { desc(:created_at) }

  private

  def role_or_triggered_by_present?
    if self.role.blank? && self.triggered_by_id.blank?
      self.errors.add(:base,"Either role or triggered_by is required.")
    end
  end

end