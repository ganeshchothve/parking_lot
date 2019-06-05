class UserObserver < Mongoid::Observer
  include ApplicationHelper

  def before_create user
    user.allowed_bookings = current_client.allowed_bookings_per_user
    user.booking_portal_client_id ||= current_client.id
    if user.role?("user") && user.email.present?
      email = user.email
      if current_client.email_domains.include?(email.split("@")[1]) && current_client.enable_company_users?
        user.role = "employee_user"
      end
    end
  end

  def before_save user
    user.generate_referral_code
    if user.phone.present?
      user.phone = Phonelib.parse(user.phone).to_s
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
    if user.manager_id_changed? && user.manager_id.present?
      user.referenced_manager_ids << user.manager_id
      user.referenced_manager_ids.uniq!
    end
    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end

  def after_update user
    if user.manager_id_changed? && user.manager_id.present?
      if user.buyer? && user.manager_role?("channel_partner")
        email = Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "user_manager_changed").id,
          recipients: [user],
          cc_recipients: [user.manager],
          triggered_by_id: user,
          triggered_by_type: user.class.to_s
        })
        email.sent!
      end
    end
  end
end
