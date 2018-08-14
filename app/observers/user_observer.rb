class UserObserver < Mongoid::Observer
  include ApplicationHelper

  def before_create user
    user.booking_portal_client_id = current_client.id
    if user.role?("user")
      email = user.email
      client = user.booking_portal_client
      if client.email_domains.include?(email.split("@")[1])
        user.role = "employee_user"
      end
    end
  end

  def before_save user
    user.phone.gsub(" ", "")
    if user.manager_id_changed? && user.manager_id.present?
      user.referenced_manager_ids << user.manager_id
    end
    if user.confirmed_at_changed?
      # manager_ids = user.referenced_manager_ids - [user.manager_id]
      # manager_ids.each do |manager_id|
      #   mailer = ChannelPartnerMailer.send_user_activated_with_other(manager_id, user.id)
      #   if Rails.env.development?
      #     mailer.deliver
      #   else
      #     mailer.deliver_later
      #   end
      # end
      user.referenced_manager_ids = [user.manager_id]
    end
    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end
end
