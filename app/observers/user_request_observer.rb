class UserRequestObserver < Mongoid::Observer
  def after_save(user_request)
    if user_request.event.present?
      user_request.send(user_request.event) if %w[rejected processing].exclude?(user_request.event) # remove code
    end
  end
end
