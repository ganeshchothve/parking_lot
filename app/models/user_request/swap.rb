class UserRequest::Swap < UserRequest
  field :alternate_project_unit_id, type: BSON::ObjectId # in case of swap resolve

  validate :alternate_project_unit_availability, :alternate_project_unit_blocking_condition, unless: proc { |user_request| %w[processing resolved].include?(user_request.status) }

  enable_audit(
    indexed_fields: %i[booking_detail_id receipt_id],
    audit_fields: %i[status alternate_project_unit_id booking_detail_id],
    reference_ids_without_associations: [
      { field: 'alternate_project_unit_id', klass: 'ProjectUnit' }
    ]
  )

  def alternate_project_unit
    ProjectUnit.where(id: alternate_project_unit_id).first
  end

  private

  def alternate_project_unit_availability
    if %w[rejected failed].exclude?(status)
      valid = alternate_project_unit.status == 'available' || (alternate_project_unit.status == 'hold' && alternate_project_unit.user_id == booking_detail.project_unit.user_id)

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
    unless alternate_project_unit.blocking_amount <= booking_detail.project_unit.blocking_amount
      _total_tentative_amount_paid = booking_detail.project_unit.total_tentative_amount_paid
      if _total_tentative_amount_paid < alternate_project_unit.blocking_amount
        errors.add(:alternate_project_unit, "has blocking amount #{alternate_project_unit.blocking_amount}, which is higher than your tentative paid amount ( #{_total_tentative_amount_paid} ).")
      end
    end
  end
end
