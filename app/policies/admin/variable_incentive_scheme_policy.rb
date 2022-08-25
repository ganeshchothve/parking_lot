class Admin::VariableIncentiveSchemePolicy < VariableIncentiveSchemePolicy
  def index?
    %w[superadmin].include?(user.role) & current_client.enable_channel_partners?
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def show?
    %w[superadmin].include?(user.role)
  end

  def end_scheme?
    record.approved? && (record.start_date <= Date.current && Date.current < record.end_date) && update?
  end

  def vis_details?
    %w[superadmin admin billing_team channel_partner cp_owner].include?(user.role)
  end

  def export?
    vis_details?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:name]
    if record.draft?
      attributes += [:event] if user.role.in?(%w(superadmin))
      attributes += [:days_multiplier, :total_bookings_multiplier, :min_incentive, :scheme_days, :average_revenue_or_bookings, :max_expense_percentage, :start_date, :end_date, :total_bookings, :total_inventory]
      attributes += [project_ids: []]
    end
    # For disabling approved scheme till they are not started.
    attributes += [:event] if user.role.in?(%w(superadmin)) && record.approved?
    attributes.uniq
  end
end
