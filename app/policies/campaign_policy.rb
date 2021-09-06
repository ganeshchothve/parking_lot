class CampaignPolicy < ApplicationPolicy
  def index?
    true
  end

  def permitted_attributes(_params = {})
    []
  end
end
