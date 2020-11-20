class ThirdPartyReferencePolicy < ApplicationPolicy

  def permitted_attributes(params = {})
    [:id, :crm_id, :reference_id]
  end
end
