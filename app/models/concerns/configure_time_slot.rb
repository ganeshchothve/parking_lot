module ConfigureTimeSlot
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do
    # Fields
    field :slot_start_date, type: DateTime
    field :start_time, type: Time
    field :end_time, type: Time
    field :duration, type: Integer # minutes
    field :capacity, type: Integer, default: 1
    field :token_number_prefix, type: String, default: 'TKN'
    field :token_number_seed, type: Integer
    field :enable_slot_generation, type: Boolean, default: false

    # Validations
    validates :slot_start_date, :start_time, :end_time, :duration, :capacity, presence: true, if: :enable_slot_generation
    validates :capacity, numericality: { greater_than: 0 }, if: :capacity?
    validates :duration, numericality: { greater_than: 0 }, if: :duration?
    validates :token_number_seed, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :check_duration, if: ->(record) { record.duration? && record.start_time? && record.end_time? }
    validate :check_end_time, if: ->(record) { record.start_time? && record.end_time? }

    # Callbacks
    after_save :update_seed
  end

  # Methods
  def check_duration
    errors.add(:duration, 'Duration is too long to fit a slot in one day.') if end_time < start_time + duration.minutes
  end

  def check_end_time
    errors.add(:end_time, 'End Time must be more than start time.') if start_time >= end_time
  end

  def update_seed
    Mongoid::Autoinc::Incrementor.new('Receipt', :token_number, { seed: token_number_seed }).update if token_number_seed_changed? && token_number_seed.present?
  end
end
