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
    # release the unit immediately
    if user_request.project_unit_id.present?
      unit = user_request.project_unit
      unit.make_available
      unit.save!
    end
  end

  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved'
      mailer = UserRequestMailer.send_resolved(user_request.id.to_s)
      if user_request.project_unit.present? && (user_request.request_type == "cancellation") && ["blocked", "booked_tentative", "booked_confirmed"].include?(user_request.project_unit.status)
        project_unit = user_request.project_unit
        project_unit.status = "available"
        project_unit.save(validate: false)
      end
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end
  end
end
