class UserRequestObserver < Mongoid::Observer
  def after_create user_request
    if user_request.status == 'pending'
      mailer = UserRequestMailer.send_pending(user_request.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end
  end

  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved'
      mailer = UserRequestMailer.send_resolved(user_request.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end
  end
end
