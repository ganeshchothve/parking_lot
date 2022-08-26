class Admin::AnnouncementPolicy < AnnouncementPolicy

  def index?
    user.role.in?(%w(superadmin admin)) && user.booking_portal_client.enable_channel_partners?
  end
  
  def show?
    ['channel_partner', 'cp_owner', 'superadmin', 'admin'].include?(user.role)
  end

  def new?
    %w(admin superadmin).include?(user.role)
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

  def destroy?
    new?
  end

  def asset_create?
    new?
  end

  def permitted_attributes(_params = {})
    attributes = ['category', 'title', 'content', 'date', 'is_active']
    attributes
  end
end
