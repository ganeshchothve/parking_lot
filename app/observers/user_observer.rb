class UserObserver < Mongoid::Observer
  include ApplicationHelper

  def before_create user
    user.allowed_bookings = current_client.allowed_bookings_per_user
    user.booking_portal_client_id = current_client.id
    if user.role?("user") && user.email.present?
      email = user.email
      client = user.booking_portal_client
      if client.email_domains.include?(email.split("@")[1]) && current_client.enable_company_users?
        user.role = "employee_user"
      end
    end
  end

  def before_save user
    user.phone.gsub(" ", "") if user.phone.present?
    if user.manager_id_changed? && user.manager_id.present?
      user.referenced_manager_ids << user.manager_id
      if user.buyer?
        mailer = UserMailer.send_change_in_manager(user.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      end
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
