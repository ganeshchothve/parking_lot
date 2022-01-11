class ChannelPartnerObserver < Mongoid::Observer
  include ApplicationHelper

  def after_create channel_partner
    query = []
    query << { phone: channel_partner.phone } if channel_partner.phone.present?
    query << { email: channel_partner.email } if channel_partner.email.present?
    user = User.in(role: %w(channel_partner cp_owner)).or(query).first
    if user.present?
      # if user is already present & new company is created with it then change channel partner id on user. Handled in controller, to create a channel partner company only when user account is inactive under a different cp company.
      # This will provide a mechanism for channel partner user to register a new company & keep the same account without the old leads data.
      user.assign_attributes(first_name: channel_partner.first_name, last_name: channel_partner.last_name,channel_partner_id: channel_partner.id, is_active: true, role: 'cp_owner', rera_id: channel_partner.rera_id, email: channel_partner.email, manager_id: channel_partner.manager_id, channel_partner: channel_partner)
    else
      user = User.new(first_name: channel_partner.first_name, last_name: channel_partner.last_name, email: channel_partner.email, phone: channel_partner.phone, rera_id: channel_partner.rera_id, role: 'cp_owner', booking_portal_client_id: current_client.id, manager_id: channel_partner.manager_id, channel_partner: channel_partner)
    end

    if channel_partner.referral_code.present?
      query = []
      query << { phone: user.phone } if user.phone.present?
      query << { email: user.email } if user.email.present?
      referral = Referral.where(referral_code: channel_partner.referral_code).or(query).first
      if referral
        user.set(referred_by_id: referral.referred_by_id, referred_on: referral.created_at)
      elsif (referred_by = User.where(referral_code: channel_partner.referral_code).first)
        user.set(referred_by_id: referred_by.id, referred_on: Time.now)
      end
    end

    unless channel_partner.is_existing_company.present?
      user.active
    end
    user.save!
    channel_partner.set(primary_user_id: user.id)

    if (selldo_api_key = user&.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = user&.booking_portal_client&.selldo_client_id.presence)
      SelldoLeadUpdater.perform_async(user.id.to_s, {stage: channel_partner.status, action: 'add_cp_portal_stage', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id})
      # Push services interested to selldo if set or changed
      SelldoLeadUpdater.perform_async(user.id.to_s, {action: 'push_cp_data', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id, lead: {custom_interested_services: channel_partner.interested_services.join(',')}})
    end

    # For pushing inactive status event in Interakt
    if current_client.external_api_integration?
      if Rails.env.staging? || Rails.env.production?
        ChannelPartnerObserverWorker.perform_async(channel_partner.id.to_s, { 'status' => [nil, channel_partner.status] })
      else
        ChannelPartnerObserverWorker.new.perform(channel_partner.id, { 'status' => [nil, channel_partner.status] })
      end
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
      if channel_partner.manager_id_changed? && channel_partner.manager_id.present?
        channel_partner.users.update_all(manager_id: channel_partner.manager_id)
      end
    end
    channel_partner.rera_applicable = true if channel_partner.rera_id.present?
    channel_partner.gst_applicable = true if channel_partner.gstin_number.present?

    # For calling Selldo & Interakt APIs
    if current_client.external_api_integration? && channel_partner.persisted? && channel_partner.changed?
      if Rails.env.staging? || Rails.env.production?
        ChannelPartnerObserverWorker.perform_async(channel_partner.id.to_s, channel_partner.changes)
      else
        ChannelPartnerObserverWorker.new.perform(channel_partner.id, channel_partner.changes)
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
