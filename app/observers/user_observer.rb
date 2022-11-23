class UserObserver < Mongoid::Observer
  include ApplicationHelper

  def before_validation user
    user.allowed_bookings ||= user.booking_portal_client.allowed_bookings_per_user
    # user.booking_portal_client_id ||= user.booking_portal_client.id
    user.phone = Phonelib.parse(user.phone).to_s if user.phone.present?

    user.assign_attributes(manager_change_reason: 'Blocking the lead', unblock_at: Date.today + user.booking_portal_client.lead_blocking_days) if user.temporarily_blocked == true && user.unblock_at == nil && user.booking_portal_client.lead_blocking_days.present?

    _event = user.event.to_s
    user.event = nil
    if _event.present?
      if user.send("may_#{_event.to_s}?")
        user.aasm(:company).fire!(_event.to_sym)
      else
        user.errors.add(:status, 'transition is invalid')
      end
    end
  end

  def before_create user
    user.generate_referral_code
    user.generate_cp_code
    if user.role?("user") && user.email.present?
      email = user.email
      if user.booking_portal_client.email_domains.include?(email.split("@")[1]) && user.booking_portal_client.enable_company_users?
        user.role = "employee_user"
      end
    end
    if user.channel_partner_id.present? && user.channel_partner.manager_id.present? && user.role.in?(%w(cp_owner channel_partner))
      user.manager_id = user.channel_partner.manager_id
    elsif ENV_CONFIG[:default_cp_manager_id].present?
      user.manager_id = ENV_CONFIG[:default_cp_manager_id]
    end
  end

  def after_create user
    if user.booking_portal_client.external_api_integration?
      if user.role.in?(%w(cp_owner channel_partner))
        if Rails.env.staging? || Rails.env.production?
          # Kept create user api call inline to avoid firing update calls before create which will fail to find user to update
          UserObserverWorker.new.perform(user.id.to_s, 'create')
          UserObserverWorker.perform_async(user.id.to_s, 'update', user.changes)
        else
          UserObserverWorker.new.perform(user.id.to_s, 'create')
          UserObserverWorker.new.perform(user.id, 'update', user.changes)
        end
      end
      if user.role.in?(%w(dev_sourcing_manager))
        if Rails.env.staging? || Rails.env.production?
          UserObserverWorker.perform_async(user.id.to_s, 'create')
        else
          UserObserverWorker.new.perform(user.id.to_s, 'create')
        end
      end
    end
  end

  def before_save user
    if user.confirmed_at_changed? && user.confirmed?
      # Send confirmed portal stage for channel partner users into selldo
      if user.channel_partner?
        user.set_portal_stage_and_push_in_crm
      end
    end

    if user.role.in?(%w(cp_owner channel_partner dev_sourcing_manager))
      user.rera_id = user.channel_partner&.rera_id if user.rera_id.blank? && user.role.in?(%w(cp_owner channel_partner))

      if user.booking_portal_client.external_api_integration? && user.persisted? && user.changed?
        if Rails.env.staging? || Rails.env.production?
          UserObserverWorker.perform_async(user.id.to_s, 'update', user.changes)
        else
          UserObserverWorker.new.perform(user.id, 'update', user.changes)
        end
      end
    end

    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end

  def after_save user
    if user.lead_id.present? && crm = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      user.update_external_ids({ reference_id: user.lead_id }, crm.id)
    end
    user.calculate_incentive if user.booking_portal_client.present? && user.booking_portal_client.incentive_calculation_type?("calculated")
    user.move_invoices_to_draft

    if user.active? && user.role.in?(%w(cp_owner channel_partner)) && (user.changes.keys & %w(first_name last_name email phone)).present?
      if Rails.env.staging? || Rails.env.production?
        GenerateCoBrandingTemplatesWorker.perform_in(60.seconds, user.id.to_s)
      else
        GenerateCoBrandingTemplatesWorker.new.perform(user.id)
      end
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
