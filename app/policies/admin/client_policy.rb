class Admin::ClientPolicy < ClientPolicy
  # def new? def create? def edit? def asset_create? from ClientPolicy

  def update?
    %w[admin superadmin].include?(user.role)
  end

  def permitted_attributes(params = {})
    attributes = super
    if %w[admin superadmin].include?(user.role)
      if Receipt.count > 0
        attributes += [:enable_slot_generation] if record.enable_slot_generation
      else
        attributes += %w[slot_start_date start_time end_time capacity duration enable_slot_generation]
      end
    end
    attributes.uniq
  end
end
