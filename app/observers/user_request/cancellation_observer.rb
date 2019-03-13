class UserRequest::CancellationObserver < Mongoid::Observer
  def after_create(user_request)
    user_request.booking_detail.cancellation_requested!
  end

  def after_update(user_request)
    ProjectUnitCancelService.new(user_request).cancel
  end
end
