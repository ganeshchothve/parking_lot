class Admin::CpLeadActivityPolicy < CpLeadActivityPolicy
  def index?
    true
  end

  def update?
    %w(admin cp_admin).include?(user.role)
  end

  def edit?
    update? && can_extend_validity? && record.count_status != 'no_count'
  end

  def show?
    true
  end

  def asset_create?
    true
  end

  private

  def can_extend_validity?
    record.lead.active_cp_lead_activities.blank?
  end
end
