class Admin::ClientPolicy < ClientPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[superadmin].include?(user.role)
  end

  def asset_create?
    update?
  end

  def index?
    update?
  end

  def create?
    update?
  end

  def permitted_attributes(params = {})
    attributes = super
    if %w[superadmin].include?(user.role)
      attributes += [:enable_slot_generation, general_user_request_categories: []]
      unless record.slot_start_date.present? && Rails.env.production?
        attributes += %w[slot_start_date start_time end_time capacity duration enable_slot_generation]
      end
      attributes += [roles_taking_registrations: []]
    end
    attributes.uniq
  end
end
