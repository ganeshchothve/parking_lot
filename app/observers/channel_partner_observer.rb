class ChannelPartnerObserver < Mongoid::Observer
  include ApplicationHelper

  def after_create channel_partner
    user = User.new(first_name: channel_partner.first_name, last_name: channel_partner.last_name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, role: 'channel_partner', booking_portal_client_id: current_client.id, manager_id: channel_partner.manager_id, channel_partner: channel_partner)
    channel_partner.set({associated_user_id: user.id})

    if channel_partner.referral_code.present?
      referred_by_user = User.where(referral_code: channel_partner.referral_code).first
      if referred_by_user
        user.set(referred_by_id: referred_by_user.id)
      end
    end
    user.save!

    if current_client.external_api_integration?
      Crm::Api::Post.where(resource_class: 'ChannelPartner', is_active: true).each do |api|
        api.execute(channel_partner)
      end
    end

    if (selldo_api_key = user&.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = user&.booking_portal_client&.selldo_client_id.presence)
      SelldoLeadUpdater.perform_async(user.id.to_s, {stage: channel_partner.status, action: 'add_cp_portal_stage', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id})
      # Push services interested to selldo if set or changed
      SelldoLeadUpdater.perform_async(user.id.to_s, {action: 'push_cp_data', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id, lead: {custom_interested_services: channel_partner.interested_services.join(',')}})
    end

    template = Template::EmailTemplate.where(name: "channel_partner_created").first
    recipients = []
    recipients << channel_partner.manager if channel_partner.manager.present?
    recipients << channel_partner.manager.manager if channel_partner.manager.try(:manager).present?
    if template.present? && recipients.present?
      email = Email.create!({
        booking_portal_client_id: channel_partner.associated_user.booking_portal_client_id,
        email_template_id: template.id,
        recipients: recipients.flatten,
        triggered_by_id: channel_partner.id,
        triggered_by_type: channel_partner.class.to_s
      })
      email.sent!
    end
  end

  def before_save channel_partner
    # update user's details from channel partner
    if cp_user = channel_partner.associated_user.presence
      cp_user.update(first_name: channel_partner.first_name, last_name: channel_partner.last_name, rera_id: channel_partner.rera_id, manager_id: channel_partner.manager_id)

      # Push services interested to selldo if set or changed
      if (selldo_api_key = cp_user&.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = cp_user&.booking_portal_client&.selldo_client_id.presence)
        SelldoLeadUpdater.perform_async(cp_user.id.to_s, {action: 'push_cp_data', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id, lead: {custom_interested_services: channel_partner.interested_services.join(',')}})
      end
    end
    channel_partner.rera_applicable = true if channel_partner.rera_id.present?
    channel_partner.gst_applicable = true if channel_partner.gstin_number.present?

    # TODO: Handle enable_direct_activation_for_cp setting behavior on client.
    #if channel_partner.new_record? && current_client.reload.enable_direct_activation_for_cp
    #  channel_partner.status = 'active'
    #end
  end

  def after_update channel_partner
    if (channel_partner.changed & %w[rera_applicable gst_applicable rera_id gstin_number]).present?
      template = Template::EmailTemplate.where(name: "channel_partner_updated").first
      recipients = []
      recipients << channel_partner.manager if channel_partner.manager.present?
      recipients << channel_partner.manager.manager if channel_partner.manager.try(:manager).present?
      if template.present? && recipients.present?
        email = Email.create!({
          booking_portal_client_id: channel_partner.associated_user.booking_portal_client_id,
          email_template_id: template.id,
          recipients: recipients.flatten,
          triggered_by_id: channel_partner.id,
          triggered_by_type: channel_partner.class.to_s
        })
        email.sent!
      end
    end
  end
end
