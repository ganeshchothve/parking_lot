class UserRequest::Cancellation < UserRequest
  enable_audit(
    indexed_fields: %i[booking_detail_id receipt_id],
    audit_fields: %i[status booking_detail_id]
  )
end
