class ThirdPartyReferencePolicy < ApplicationPolicy

  def permitted_attributes(params = {})
    attrs = []
    attrs += [:id, :crm_id, :reference_id] if user.role.in?(%w(superadmin admin)) && !marketplace_portal?
    attrs
  end
end
