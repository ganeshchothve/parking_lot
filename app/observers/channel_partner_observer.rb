class ChannelPartnerObserver < Mongoid::Observer
  def after_create channel_partner
    ChannelPartnerMailer.send_create(channel_partner.id)
  end

  def before_save channel_partner
    # register user and set the user's id on the channel partner
    if channel_partner.status_changed? && channel_partner.status == 'active'
      user = User.create!(name: channel_partner.name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, location: channel_partner.location, role: 'channel_partner')
      # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use OTP based login

      channel_partner.associated_user_id = user.id
    end
  end

  def after_save channel_partner
    if channel_partner.status_changed? && channel_partner.status == 'active'
      # send email. Currently we dont need to implement this, because user anyway gets a notification on user creation
      # ChannelPartnerMailer.send_active(channel_partner.id)
    end
  end
end
