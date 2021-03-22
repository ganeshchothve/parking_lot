class Admin::LeadPolicy < LeadPolicy

  def index?
    out = !user.buyer?
    out && user.active_channel_partner?
  end

  def export?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def edit?
    user.role.in?(%w(superadmin admin))
  end

  def update?
    edit?
  end

  def asset_create?
    %w[admin sales sales_admin crm].include?(user.role)
  end

  def permitted_attributes(params = {})
    attributes = super || []
    if user.role.in?(%w(superadmin admin))
      attributes += [:manager_id, third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes]
    end
  end
end
