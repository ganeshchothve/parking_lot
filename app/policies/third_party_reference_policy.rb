class ThirdPartyReferencePolicy < ApplicationPolicy

  def permitted_attributes(params = {})
    attrs = []
    attrs += [:id, :crm_id, :reference_id] if user.role?('superadmin')
    attrs
  end
end
