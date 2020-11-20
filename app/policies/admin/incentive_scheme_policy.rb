class Admin::IncentiveSchemePolicy < IncentiveSchemePolicy

  def index?
    user.role.in?(%w(superadmin admin))
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def end_scheme?
    !record.default? && record.approved? && (record.starts_on <= Date.current && Date.current < record.ends_on) && update?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:name]
    if record.draft?
      attributes += [:event] if user.role.in?(%w(admin superadmin))
      attributes += [:starts_on, :ends_on, :ladder_strategy, :project_id, :project_tower_id, :tier_id, ladders_attributes: LadderPolicy.new(user, record.ladders.first).permitted_attributes]
    end
    attributes.uniq
  end
end
