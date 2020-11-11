class Admin::LeadPolicy < LeadPolicy

  def index?
    !user.buyer?
  end

  def edit?
    user.role.in?(%w(superadmin admin))
  end

  def update?
    edit?
  end

  def permitted_attributes(params = {})
    attributes = super || []
    if user.role.in?(%w(superadmin admin))
      attributes += [:manager_id, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
    end
  end
end
