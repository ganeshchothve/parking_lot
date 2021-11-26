class ChannelPartnerObserver < Mongoid::Observer
  include ApplicationHelper

  def after_create channel_partner
    user = User.new(first_name: channel_partner.first_name, last_name: channel_partner.last_name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, role: 'cp_owner', booking_portal_client_id: current_client.id, manager_id: channel_partner.manager_id, channel_partner: channel_partner, is_active: false)

    if channel_partner.referral_code.present?
      referred_by_user = User.where(referral_code: channel_partner.referral_code).first
      if referred_by_user
        user.set(referred_by_id: referred_by_user.id)
      end
    end
    user.save!

    if (selldo_api_key = user&.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = user&.booking_portal_client&.selldo_client_id.presence)
      SelldoLeadUpdater.perform_async(user.id.to_s, {stage: channel_partner.status, action: 'add_cp_portal_stage', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id})
      # Push services interested to selldo if set or changed
      SelldoLeadUpdater.perform_async(user.id.to_s, {action: 'push_cp_data', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id, lead: {custom_interested_services: channel_partner.interested_services.join(',')}})
    end

    template_name = "channel_partner_created"
    template = Template::EmailTemplate.where(name: template_name).first
    recipients = []
    recipients << channel_partner.manager if channel_partner.manager.present?
    recipients << channel_partner.manager.manager if channel_partner.manager.try(:manager).present?
    if template.present? && recipients.present?
      email = Email.create!({
        booking_portal_client_id: current_client.id,
        email_template_id: template.id,
        recipients: recipients.flatten,
        triggered_by_id: channel_partner.id,
        triggered_by_type: channel_partner.class.to_s
      })
      email.sent!
    end
    sms_template = Template::EmailTemplate.where(name: template_name).first
    if sms_template.present?
      phones = recipients.collect(&:phone).reject(&:blank?)
      if phones.present?
        Sms.create!(
          booking_portal_client_id: current_client.id,
          to: phones,
          sms_template_id: sms_template.id,
          triggered_by_id: channel_partner.id,
          triggered_by_type: channel_partner.class.to_s
        )
      end
    end
  end

  def before_save channel_partner
    # update user's details from channel partner
    if channel_partner.users.present?
      if channel_partner.rera_id_changed? && channel_partner.rera_id.present?
        channel_partner.users.update_all(rera_id: channel_partner.rera_id)
      end

      # Push services interested to selldo if set or changed
      if channel_partner.interested_services_changed? && channel_partner.interested_services.present?
        channel_partner.users.cp_owner.each do |cp_user|
          if (selldo_api_key = cp_user&.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = cp_user&.booking_portal_client&.selldo_client_id.presence)
            SelldoLeadUpdater.perform_async(cp_user.id.to_s, {action: 'push_cp_data', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id, lead: {custom_interested_services: channel_partner.interested_services.join(',')}})
          end
        end
      end
    end
    channel_partner.rera_applicable = true if channel_partner.rera_id.present?
    channel_partner.gst_applicable = true if channel_partner.gstin_number.present?

    if channel_partner.manager_id_changed? && channel_partner.manager_id.present?
      channel_partner.users.update_all(manager_id: channel_partner.manager_id)
      if current_client.external_api_integration?
        Crm::Api::Put.where(resource_class: 'ChannelPartner', is_active: true).each do |api|
          api.execute(channel_partner)
        end
      end
    end
  end

  def after_update channel_partner
    if (channel_partner.changed & %w[rera_applicable gst_applicable rera_id gstin_number]).present?
      recipients = []
      recipients << channel_partner.manager if channel_partner.manager.present?
      recipients << channel_partner.manager.manager if channel_partner.manager.try(:manager).present?
      if recipients.present?
        template_name = "channel_partner_updated"
        template = Template::EmailTemplate.where(name: template_name).first
        if template.present?
          email = Email.create!({
            booking_portal_client_id: current_client.id,
            email_template_id: template.id,
            recipients: recipients.flatten,
            triggered_by_id: channel_partner.id,
            triggered_by_type: channel_partner.class.to_s
          })
          email.sent!
        end
        sms_template = Template::EmailTemplate.where(name: template_name).first
        if sms_template.present?
          phones = recipients.collect(&:phone).reject(&:blank?)
          if phones.present?
            Sms.create!(
              booking_portal_client_id: current_client.id,
              to: phones,
              sms_template_id: sms_template.id,
              triggered_by_id: channel_partner.id,
              triggered_by_type: channel_partner.class.to_s
            )
          end
        end
      end
    end
  end
end
