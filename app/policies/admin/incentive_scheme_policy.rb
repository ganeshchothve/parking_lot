class Admin::IncentiveSchemePolicy < IncentiveSchemePolicy

  def index?
    %w[superadmin admin cp_admin].include?(user.role) && enable_incentive_module?(user)
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

  def asset_create?
    index?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:name, :description, :terms_and_conditions]
    if record.draft?
      attributes += [:event] if user.role.in?(%w(admin superadmin))
      attributes += [:category, :resource_class, :brokerage_type, :payment_to, :auto_apply, :starts_on, :ends_on, :ladder_strategy, :project_id, :project_tower_id, :tier_id, ladders_attributes: LadderPolicy.new(user, Ladder.new).permitted_attributes]
    end
    # For disabling approved scheme till they are not started.
    attributes += [:event] if user.role.in?(%w(admin superadmin)) && record.approved?
    attributes.uniq
  end
end
