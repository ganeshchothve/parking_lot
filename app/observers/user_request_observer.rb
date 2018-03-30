class UserRequestObserver < Mongoid::Observer
  def after_create user_request
    if user_request.status == 'pending'
      mailer = UserRequestMailer.send_pending(user_request.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      user = user_request.user
      project_unit = user_request.project_unit
      if project_unit.present?
        message = "We’re sorry to see you go! Your request for cancellation of booking for #{project_unit.name} has been received. Our CRM team will get in touch with you shortly."
        if Rails.env.development?
          SMSWorker.new.perform(user.phone.to_s, message)
        else
          SMSWorker.perform_async(user.phone.to_s, message)
        end
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
