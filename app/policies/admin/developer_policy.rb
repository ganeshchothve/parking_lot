class Admin::DeveloperPolicy < DeveloperPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin admin].include?(user.role)
  end

  def asset_create?
    %w[superadmin admin].include?(user.role)
  end

  def asset_update?
    asset_create?
  end

  def index?
    !user.buyer? && (user.booking_portal_client.enable_actual_inventory?(user) || enable_incentive_module?(user))
  end

  def show?
    index?
  end

  def create?
    update?
  end

  def ds?
    user.booking_portal_client.enable_actual_inventory?(user)
  end

  def permitted_attributes(params = {})
    attributes = [:name]
    if user.role?(:superadmin)
      attributes += [
        :selldo_id
      ]
    end
    attributes.uniq
  end
end
