class UserRequestObserver < Mongoid::Observer
  def after_save(user_request)
    _event = user_request.event
    user_request.event = nil
    user_request.send("#{_event}!") if _event.present?
  end
end
