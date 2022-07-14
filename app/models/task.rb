class Task
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :key, type: String
  field :tracked_by, type: String
  field :completed_at, type: DateTime
  field :completed, type: Boolean
  field :order, type: Integer

  validates :name, :key, :tracked_by, :order, presence: true
  validates :key, :name, :order, uniqueness: { scope: :booking_detail_id }
  validate :check_system_task

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  embedded_in :booking_detail
  belongs_to :completed_by, class_name: 'User', optional: true

  alias :name_in_error :name

  def check_system_task
    errors.add :completed, 'system task cannot be undone' if self.tracked_by == 'system' && self.completed_changed? && self.completed_was.present?
  end
end
