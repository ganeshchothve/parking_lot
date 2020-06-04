class ChannelPartnerObserver < Mongoid::Observer
  include ApplicationHelper
  def after_create channel_partner
    ChannelPartnerMailer.send_create(channel_partner.id)
  end

  def before_save channel_partner
    if current_client.enable_direct_activation_for_cp
      channel_partner.status = 'active'
    end
    # register user and set the user's id on the channel partner
    if channel_partner.associated_user_id.blank? && channel_partner.status_changed? && channel_partner.status == 'active'
      user = User.create!(first_name: channel_partner.first_name, last_name: channel_partner.last_name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, role: 'channel_partner', booking_portal_client_id: current_client.id, manager_id: channel_partner.manager_id)
      # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use OTP based login

      channel_partner.associated_user_id = user.id
    end
  end

  def after_save channel_partner
    if channel_partner.status_changed? && channel_partner.status == 'active'
    end
  end
end
