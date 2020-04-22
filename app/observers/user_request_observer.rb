class UserRequestObserver < Mongoid::Observer
  def before_validation(user_request)
    _event = user_request.event
    user_request.event = nil
    if _event.present? && (user_request.aasm.current_state.to_s != _event.to_s)
      if user_request.send("may_#{_event}?")
        user_request.send("#{_event}!")
      else
        user_request.errors.add(:status, 'transition is invalid')
      end
    end
  end

  def after_create user_request
    user_request.update_requestable_to_request_made
  end
end
