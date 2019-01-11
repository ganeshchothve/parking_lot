class UserRequest::Swap < UserRequest
  field :alternate_project_unit_id, type: BSON::ObjectId # in case of swap resolve

  validate :alternate_project_unit_availability, :alternate_project_unit_blocking_condition

  enable_audit({
    indexed_fields: [:project_unit_id, :receipt_id],
    audit_fields: [:status, :alternate_project_unit_id, :project_unit_id],
    reference_ids_without_associations: [
      {field: 'alternate_project_unit_id', klass: 'ProjectUnit'},
    ]
  })

  def alternate_project_unit
    ProjectUnit.where(id: self.alternate_project_unit_id).first
  end

  private

  def alternate_project_unit_availability
    if ['rejected', 'failed'].exclude?(self.status)
      valid = self.alternate_project_unit.status == "available" || (self.alternate_project_unit.status == "hold" && self.alternate_project_unit.user_id == self.project_unit.user_id)

      if !valid
        self.errors.add(:alternate_project_unit_id, "is not available for booking.")
      end
    end
  end

  #
  # Blocking amount is related to project unit. So it may be different.
  # As per booking rule buyer need to pay atleast bocking amount.
  # So buyer's paid amount ( Success and Pending ) for booked unit should be greater than eqaul to alternative unit blocking amount.
  #
  #
  def alternate_project_unit_blocking_condition
    unless self.alternate_project_unit.blocking_amount <= self.project_unit.blocking_amount
      _total_tentative_amount_paid = self.project_unit.total_tentative_amount_paid
      if _total_tentative_amount_paid < self.alternate_project_unit.blocking_amount
        Alternate project unit has blocking amount 50000 is higher than your tentative paid amount ( _total_tentative_amount_paid ).
        self.errors.add(:alternate_project_unit, "has blocking amount #{ self.alternate_project_unit.blocking_amount }, which is higher than your tentative paid amount ( #{_total_tentative_amount_paid} ).")
      end
    end
  end
end
