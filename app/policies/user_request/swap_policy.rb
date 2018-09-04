class UserRequest::SwapPolicy < UserRequestPolicy
  def permitted_attributes params={}
    attributes = super
    if record.status == "pending"
      attributes += [:alternate_project_unit_id] if ['admin', 'crm', 'sales', 'superadmin', 'cp'].include?(user.role) || (user.buyer? && record.user_id == user.id)
    end
    attributes
  end
end
