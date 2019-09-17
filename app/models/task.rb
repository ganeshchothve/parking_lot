class Task
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :key, type: String
  field :tracked_by, type: String
  field :completed_at, type: DateTime
  field :completed, type: Boolean

  embedded_in :booking_detail
  belongs_to :completed_by, class_name: 'User', optional: true
end
