class Buyer::CampaignPolicy < CampaignPolicy
  def show?
    roles = User::BUYER_ROLES
    roles -= %w[user employee_user management_user] unless ['scheduled', 'completed'].include?(record.status)
    roles.uniq.present?
  end

  def new?
    false
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
  attributes = super
  attributes
  end
end
