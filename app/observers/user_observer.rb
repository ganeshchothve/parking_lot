class UserObserver < Mongoid::Observer
  def before_create user
    if user.role?("user")
      email = user.email
      client = user.booking_portal_client
      if client.email_domains.include?(email.split("@")[1])
        user.role = "employee_user"
      end
    end
  end

  def before_save user
    if user.channel_partner_id_changed? && user.channel_partner_id.present?
      user.referenced_channel_partner_ids << user.channel_partner_id
    end
    if user.confirmed_at_changed?
      # channel_partner_ids = user.referenced_channel_partner_ids - [user.channel_partner_id]
      # channel_partner_ids.each do |channel_partner_id|
      #   mailer = ChannelPartnerMailer.send_user_activated_with_other(channel_partner_id, user.id)
      #   if Rails.env.development?
      #     mailer.deliver
      #   else
      #     mailer.deliver_later
      #   end
      # end
      user.referenced_channel_partner_ids = [user.channel_partner_id]
    end
    if user.buyer? && user.channel_partner_id.present?
      template_id = SmsTemplate.find_by(name: "user_registered_by_channel_partner").id
    elsif user.role == "channel_partner"
      template_id = SmsTemplate.find_by(name: "channel_partner_user_registered").id
    else
      template_id = SmsTemplate.find_by(name: "user_registered").id
    end

    Sms.create!(
      booking_portal_client_id: user.booking_portal_client_id,
      recipient_id: user.id,
      sms_template_id: template_id,
      triggered_by_id: user.id,
      triggered_by_type: user.class.to_s
    )

    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end
end
