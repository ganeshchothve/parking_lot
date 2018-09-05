class UserRequest::Swap < UserRequest
  field :alternate_project_unit_id, type: BSON::ObjectId # in case of swap resolve

  validate :alternate_project_unit_availability

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
    valid = self.alternate_project_unit.status == "available" || (self.alternate_project_unit.status == "hold" && self.alternate_project_unit.user_id == self.project_unit.user_id)

    if !valid
      self.errors.add(:alternate_project_unit_id, "is not available for booking.")
    end
  end
end
