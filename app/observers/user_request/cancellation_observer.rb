class UserRequest::CancellationObserver < Mongoid::Observer
  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved' && user_request.project_unit.present?

      make_project_unit_available &&= ["blocked", "booked_tentative", "booked_confirmed"].include?(user_request.project_unit.status)
      make_project_unit_available &&= user_request.user_id == user_request.project_unit.user_id

      if make_project_unit_available
        project_unit = user_request.project_unit
        project_unit.processing_user_request = true
        project_unit.make_available
        project_unit.save(validate: false)
      end
    end
  end
end
