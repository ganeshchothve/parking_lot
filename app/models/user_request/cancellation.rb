class UserRequest::Cancellation < UserRequest

  enable_audit({
    indexed_fields: [:project_unit_id, :receipt_id],
    audit_fields: [:status, :project_unit_id]
  })
end
