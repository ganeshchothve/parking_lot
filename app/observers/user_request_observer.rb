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
        template = SmsTemplate.where(name: "#{user_request.request_type}_request_created").first
        if template.present?
          message = template.parsed_content(user_request)
          if Rails.env.development?
            SMSWorker.new.perform(user.phone.to_s, message)
          else
            SMSWorker.perform_async(user.phone.to_s, message)
          end
        end
      end
    end
  end

  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved' && user_request.request_type == "cancellation"
      mailer = UserRequestMailer.send_resolved(user_request.id.to_s)
      if user_request.project_unit.present? && (user_request.request_type == "cancellation") && ["blocked", "booked_tentative", "booked_confirmed"].include?(user_request.project_unit.status)
        project_unit = user_request.project_unit
        project_unit.processing_user_request = true
        project_unit.make_available
        project_unit.save(validate: false)
      end
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
    elsif user_request.status_changed? && user_request.status == 'resolved' && user_request.request_type == "swap"
      mailer = UserRequestMailer.send_swapped(user_request.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      ProjectUnitSwapService.new(user_request.project_unit_id, user_request.alternate_project_unit_id).swap
    end

    template = SmsTemplate.where(name: "#{user_request.request_type}_request_resolved").first
    if template.present?
      message = template.parsed_content(user_request)
      if Rails.env.development?
        SMSWorker.new.perform(user.phone.to_s, message)
      else
        SMSWorker.perform_async(user.phone.to_s, message)
      end
    end
  end
end
