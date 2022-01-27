class Invoice::Calculated < Invoice

  field :ladder_id, type: BSON::ObjectId
  field :ladder_stage, type: Integer

  belongs_to :incentive_scheme, class_name: "IncentiveScheme"

  validates :ladder_id, :ladder_stage, presence: true
  #validates :booking_detail_id, uniqueness: { scope: [:incentive_scheme_id, :ladder_id] }

  delegate :name, to: :incentive_scheme, prefix: true, allow_nil: true

  def amount_before_deduction
    amount
  end

end
