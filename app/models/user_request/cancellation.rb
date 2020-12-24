class UserRequest::Cancellation < UserRequest
  
  validates :requestable_id, :requestable_type, presence: true, if: proc { |user_request| user_request.user_id.present? && user_request.user.buyer? }
  validates :status, inclusion: { in: STATUS }
  validates :reason_for_failure, presence: true, if: proc { |record| record.rejected? }
  validates_uniqueness_of :requestable_id, scope: [:requestable_type, :status], if: proc{|record| record.pending? }, allow_blank: true

  enable_audit(
    indexed_fields: %i[booking_detail_id receipt_id],
    audit_fields: %i[status booking_detail_id]
  )
end
