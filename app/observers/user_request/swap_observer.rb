class UserRequest::SwapObserver < Mongoid::Observer
  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved'
      ProjectUnitSwapService.new(user_request.project_unit_id, user_request.alternate_project_unit_id).swap
    end
  end
end
