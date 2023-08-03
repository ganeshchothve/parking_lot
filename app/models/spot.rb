class Spot
  include Mongoid::Document
  include Mongoid::Timestamps

  SPOT_STATUSES = %w(available blocked)

  field :status, type: String, default: 'available'
  field :spot_number, type: Integer

  has_one :ticket
  belongs_to :parking_site

  validates :status, inclusion: { in: SPOT_STATUSES }
  validates :spot_number, numericality: { greater_than: 0 }
end
