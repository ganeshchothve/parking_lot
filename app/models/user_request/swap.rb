class UserRequest::Swap < UserRequest

  belongs_to :alternate_project_unit, class_name: 'ProjectUnit'
  has_many :booking_details, class_name: 'BookingDetail', foreign_key: :parent_booking_detail_id, primary_key: :requestable_id
  
  validates :requestable_id, :requestable_type, presence: true, if: proc { |user_request| user_request.user_id.present? && user_request.user.buyer? }
  validate :alternate_project_unit_availability,
           :alternate_project_unit_blocking_condition,
           :alternate_project_unit_within_same_project,
           unless: proc { |user_request| %w[processing resolved].include?(user_request.status) }, on: :create

  validates :status, inclusion: { in: STATUS }
  validates :reason_for_failure, presence: true, if: proc { |record| record.rejected? }
  validates_uniqueness_of :requestable_id, scope: [:requestable_type, :status], if: proc{|record| record.pending? }, allow_blank: true

  enable_audit(
    indexed_fields: %i[booking_detail_id receipt_id],
    audit_fields: %i[status alternate_project_unit_id booking_detail_id],
    reference_ids_without_associations: [
      { field: 'alternate_project_unit_id', klass: 'ProjectUnit' }
    ]
  )

  def alternative_booking_detail
    booking_details.first
  end

  private

  def alternate_project_unit_availability
    if %w[rejected failed].exclude?(status)
      valid = alternate_project_unit.status == 'available' || (alternate_project_unit.status == 'hold' && alternate_project_unit.user_id == requestable.project_unit.user_id)

      unless valid
        errors.add(:alternate_project_unit_id, 'is not available for booking.')
      end
    end
  end

  #
  # Blocking amount is related to project unit. So it may be different.
  # As per booking rule buyer need to pay atleast bocking amount.
  # So buyer's paid amount ( Success and Pending ) for booked unit should be greater than equal to alternative unit blocking amount.
  #
  #
  def alternate_project_unit_blocking_condition
    if requestable.kind_of?(BookingDetail)
      unless alternate_project_unit.blocking_amount <= requestable.blocking_amount
        _total_tentative_amount_paid = requestable.total_tentative_amount_paid
        if _total_tentative_amount_paid < alternate_project_unit.blocking_amount
          errors.add(:alternate_project_unit, "has blocking amount #{alternate_project_unit.blocking_amount}, which is higher than your tentative paid amount ( #{_total_tentative_amount_paid} ).")
        end
      end
    end
  end

  #
  # Requested new project unit in swap request must be of same project in which the booking exists.
  #
  def alternate_project_unit_within_same_project
    if requestable.kind_of?(BookingDetail)
      errors.add(:alternate_project_unit, 'must belong to same project in which booking is done.') unless requestable.project_id == alternate_project_unit.project_id
    end
  end
end
