class UserObserver < Mongoid::Observer
  def before_create user
    if user.role?("user") && user.email.include?("@embassyindia.com")
      user.role = "employee_user"
    end
  end

  def before_save user
    if user.channel_partner_id_changed? && user.channel_partner_id.present?
      user.referenced_channel_partner_ids << user.channel_partner_id
    end
    if user.confirmed_at_changed?
      channel_partner_ids = user.referenced_channel_partner_ids - [user.channel_partner_id]
      channel_partner_ids.each do |channel_partner_id|
        mailer = ChannelPartnerMailer.send_user_activated_with_other(channel_partner_id, user.id)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      end
      user.referenced_channel_partner_ids = [user.channel_partner_id]
    end
    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end
end
