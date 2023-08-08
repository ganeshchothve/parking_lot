class ThirdPartyReferencePolicy < ApplicationPolicy

  def permitted_attributes(params = {})
    attrs = []
    attrs += [:id, :crm_id, :reference_id] if user && user.role.in?(%w(superadmin admin)) && !marketplace_client?
    attrs
  end
end
