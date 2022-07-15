class TimeSlot
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc

  # Fields
  field :number, type: Integer
  field :date, type: DateTime
  field :start_time, type: Time
  field :end_time, type: Time
  field :capacity, type: Integer

  increments :number, scope: :project_id

  # Validations
  validates :date, :start_time, :end_time, :capacity, presence: true
  validate :check_start_time, if: :start_time? && :end_time?
  validates :capacity, numericality: { greater_than: 0 }
  validates :number, uniqueness: { scope: :project_id }
  validate :should_not_be_allotted, on: :destroy

  # Associations
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project
  has_many :receipts

  # Methods
  def check_start_time
    errors.add(:end_time, 'End Time must be more than start time.') if start_time >= end_time
  end

  def allotted
    receipts.count
  end

  def should_not_be_allotted
    errors.add(:base, 'Cannot delete allotted slots') unless allotted.to_i.zero?
  end

  def to_s(time_zone=nil)
    "#{date.in_time_zone(time_zone || 'Mumbai').strftime('%d/%m/%Y')} #{start_time.in_time_zone(time_zone || 'Mumbai').strftime('%I:%M %p')} - #{end_time.in_time_zone(time_zone || 'Mumbai').strftime('%I:%M %p')}"
  end

  def start_time_to_s(time_zone=nil)
    "#{date.in_time_zone(time_zone || 'Mumbai').strftime('%d/%m/%Y')} #{start_time.in_time_zone(time_zone || 'Mumbai').strftime('%I:%M %p')}"
  end

  def end_time_to_s(time_zone=nil)
    "#{date.in_time_zone(time_zone || 'Mumbai').strftime('%d/%m/%Y')} #{end_time.in_time_zone(time_zone || 'Mumbai').strftime('%I:%M %p')}"
  end
end
