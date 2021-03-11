class Invoice::Calculated < Invoice
  include NumberIncrementor

  belongs_to :incentive_scheme

  validates :ladder_id, :ladder_stage, presence: true
  validates :booking_detail_id, uniqueness: { scope: [:incentive_scheme_id, :ladder_id] }

  delegate :name, to: :incentive_scheme, prefix: true, allow_nil: true
end