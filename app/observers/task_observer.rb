class TaskObserver < Mongoid::Observer

  def before_validation task
    task.booking_portal_client_id = task.completed_by.booking_portal_client.id if task.completed_by.present?
  end

  def before_save task
    if task.completed_by.present? && task.completed_at.blank?
      task.completed_at = DateTime.now
    elsif task.completed_by.blank? && task.completed_at.present?
      task.completed_at = nil
    end
  end
end
