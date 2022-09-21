class PushNotification
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # now handled only sent and failed later will add callback
  STATUSES = %w[queued failed sent]

  field :title, type: String
  field :content, type: String
  field :data, type: Hash
  field :url, type: String
  field :status, type: String, default: 'queued' # queued, failed, sent, delivered, read, received
  field :user_notification_tokens, type: Array, default: []
  field :response, type: String # for queued, send, delivered, read message
  field :vendor, type: String, default: 'OneSignal'
  field :sent_on, type: DateTime
  field :role, type: String

  scope :filter_by_content, -> (content) { where(content: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, -> (date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, -> (status) { where(status: status) }
  scope :filter_by_project_id, -> (project_id) { where(project_id: project_id) }

  # Associations
  belongs_to :recipient, class_name: 'User', inverse_of: :received_notifications, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :notification_template, class_name: 'Template::NotificationTemplate', optional: true
  belongs_to :project, optional: true
  # Validations
  # validates :content, presence: true
  # validate :role_or_triggered_by_present?
  validates_inclusion_of :status, in: STATUSES

  # enable_audit audit_fields: [:title, :content, :created_at], reference_ids_without_associations: [{ field: 'notification_template_id', klass: 'Template::NotificationTemplate' }]

  default_scope -> { desc(:created_at) }

  private

  def role_or_triggered_by_present?
    if self.role.blank? && self.triggered_by_id.blank?
      self.errors.add(:base,"Either role or triggered_by is required.")
    end
  end

  class << self

    def user_based_scope user, params = {}
      if user.role?(:superadmin)
        custom_scope = { booking_portal_client: user.selected_client }
      else
        custom_scope = { booking_portal_client: user.booking_portal_client }
      end
      custom_scope
    end

  end

end
