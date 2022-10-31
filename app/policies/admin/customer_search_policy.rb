class Admin::CustomerSearchPolicy < CustomerSearchPolicy
  def index?
    user.role == 'gre'
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    index?
  end

  def show?
    index? && user.booking_portal_client.enable_site_visit?
  end

  def update?
    index?
  end

  def permitted_attributes
    attributes = %i[step]
  end
end
