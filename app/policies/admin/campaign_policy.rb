class Admin::CampaignPolicy < CampaignPolicy
  def show?
    if ['funding', 'funded', 'live', 'paused', 'cancelled', 'completed'].include?(record.status)
      true
    else
      ['superadmin', 'admin'].include?(user.role)
    end
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
    new? || (show? && record.status == 'scheduled')
  end

  def permitted_attributes(_params = {})
    attributes = super + [:event]
    attributes += [:name, :description, :about_campaign_manager, :campaign_type, :start_date, :end_date, :sources, :estimated_cost_per_lead, :total_budget, :terms_and_conditions, :focus, :campaign_manager_id, project_ids: [], target_areas: [], campaign_slabs_attributes: [:id, :_destroy, :name, :recommended, :minimum_investment_amount], campaign_budgets_attributes: [:id, :_destroy, :source, :total_budget, :total_spent]]  if record.new_record? || ['draft'].include?(record.status)
    attributes
  end
end