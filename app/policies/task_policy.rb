class TaskPolicy < ApplicationPolicy

  def permitted_attributes
    attributes = %w[name key tracked_by completed id completed_by_id completed_at]
  end
end
