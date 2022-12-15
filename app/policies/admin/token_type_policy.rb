class Admin::TokenTypePolicy < TokenTypePolicy

  def index?
    user.role.in?(%w(superadmin)) && !(user.booking_portal_client.launchpad_portal)
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def token_init?
    index? && !record.incrementor_exists?
  end

  def token_de_init?
    index? && record.incrementor_exists?
  end

  def permitted_attributes params={}
    attrs = super
    attrs += [:name, :token_amount]
    attrs += [:token_prefix, :token_seed] unless record.incrementor_exists?
    attrs
  end
end
