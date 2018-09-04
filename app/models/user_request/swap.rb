class UserRequest::Swap < UserRequest
  field :alternate_project_unit_id, type: BSON::ObjectId # in case of swap resolve

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
end
