class TimeSlot
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :date, type: Date
  field :start_time, type: Time
  field :end_time, type: Time

  # Validations
  validates :date, :start_time, :end_time, presence: true
  validate :check_start_time, if: :start_time? && :end_time?

  # Associations
  embedded_in :receipt

  # Methods
  def check_start_time
    errors.add(:end_time, 'End Time must be more than start time.') if start_time >= end_time
  end
end
