class InterestedProjectPolicy < ApplicationPolicy

  def index?
    false
  end

  def permitted_attributes(params = {})
    attrs = []
    attrs += [:id, :user_id, :project_id, :status]
    attrs
  end
end
