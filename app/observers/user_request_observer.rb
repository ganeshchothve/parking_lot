class UserRequestObserver < Mongoid::Observer
  def after_save(user_request)
    user_request.send(user_request.event) if user_request.event.present?
  end
end
