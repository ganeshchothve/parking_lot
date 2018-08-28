class UserRequest::CancellationPolicy < UserRequestPolicy
  def permitted_attributes params={}
    attributes = super
    if record.status == "pending"
      attributes += [:comments, :receipt_id, :user_id] if user.buyer?
      attributes += [:project_unit_id] if record.new_record?
      attributes += [:crm_comments, :reply_for_customer, :alternate_project_unit_id] if ['admin', 'crm', 'sales', 'superadmin', 'cp'].include?(user.role)
      attributes += [:status] if record.persisted?
    end
    attributes
  end
end
