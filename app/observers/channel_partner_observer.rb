class ChannelPartnerObserver < Mongoid::Observer
  include ApplicationHelper
  def after_create channel_partner
    ChannelPartnerMailer.send_create(channel_partner.id)
    user = User.create!(first_name: channel_partner.first_name, last_name: channel_partner.last_name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, role: 'channel_partner', booking_portal_client_id: current_client.id, manager_id: channel_partner.manager_id)
    channel_partner.set({associated_user_id: user.id})
  end

  def before_save channel_partner
    # update user's details from channel partner
    if channel_partner.associated_user_id.present?
      channel_partner.associated_user.update(first_name: channel_partner.first_name, last_name: channel_partner.last_name, rera_id: channel_partner.rera_id)
    end
    # TODO: Handle enable_direct_activation_for_cp setting behavior on client.
    #if channel_partner.new_record? && current_client.reload.enable_direct_activation_for_cp
    #  channel_partner.status = 'active'
    #end
  end

  def after_save channel_partner
    if channel_partner.status_changed? && channel_partner.status == 'active' && channel_partner.associated_user.present? && current_client.external_api_integration?
      Crm::Api::Post.where(resource_class: 'ChannelPartner').each do |api|
        api.execute(channel_partner)
      end
    end
  end
end
