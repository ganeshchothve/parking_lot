class UserObserver < Mongoid::Observer
  include ApplicationHelper

  def before_validation user
    user.allowed_bookings ||= current_client.allowed_bookings_per_user
    user.booking_portal_client_id ||= current_client.id
    user.phone = Phonelib.parse(user.phone).to_s if user.phone.present?

    user.assign_attributes(manager_change_reason: 'Blocking the lead', unblock_at: Date.today + user.booking_portal_client.lead_blocking_days) if user.temporarily_blocked == true && user.unblock_at == nil && user.booking_portal_client.lead_blocking_days.present?
  end

  def before_create user
    if user.role?("user") && user.email.present?
      email = user.email
      if current_client.email_domains.include?(email.split("@")[1]) && current_client.enable_company_users?
        user.role = "employee_user"
      end
    end
  end

  def after_create user
    if user.role.in?(%w(cp_owner channel_partner)) && user.channel_partner
      if current_client.external_api_integration?
        Crm::Api::Post.where(_type: 'Crm::Api::Post', resource_class: 'User', is_active: true).each do |api|
          api.execute(user)
        end
        Crm::Api::Put.where(resource_class: 'User', is_active: true).each do |api|
          api.execute(user)
        end
      end
    end
  end

  def before_save user
    user.generate_referral_code
    if user.confirmed_at_changed? && user.confirmed?
      # Send confirmed portal stage for channel partner users into selldo
      if user.channel_partner?
        if (selldo_api_key = user.booking_portal_client&.selldo_api_key.presence) && (selldo_client_id = user.booking_portal_client&.selldo_client_id.presence)
          SelldoLeadUpdater.perform_async(user.id.to_s, {stage: 'confirmed', action: 'add_cp_portal_stage', selldo_api_key: selldo_api_key, selldo_client_id: selldo_client_id})
        end
      end
    end

    if user.role.in?(%w(cp_owner channel_partner)) && user.channel_partner
      user.rera_id = user.channel_partner&.rera_id if user.rera_id.blank?

      if _changes = (user.changed & %w(role channel_partner_id)).presence && _changes.all? {|attr| user.send(attr)&.present?}
        Crm::Api::Put.where(resource_class: 'User', is_active: true).each do |api|
          api.execute(user)
        end
      end
    end

    #if user.manager_id_changed? && user.manager_id.present?
    #  if user.role?('channel_partner') && user.persisted? && cp = user.channel_partner
    #    cp.set(manager_id: user.manager_id)
    #  end
    #end

    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end

  def after_save user
    if user.lead_id.present? && crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      user.update_external_ids({ reference_id: user.lead_id }, crm.id)
    end
  end

  def after_update user
    if user.manager_id_changed? && user.manager_id.present?
      if user.buyer? && user.manager_role?("channel_partner")
        email = Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "user_manager_changed").id,
          recipient_ids: [user.id],
          cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
          cc_recipient_ids: [user.manager_id],
          triggered_by_id: user,
          triggered_by_type: user.class.to_s
        })
        email.sent!
      end

    end
  end
end
