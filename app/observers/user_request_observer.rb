class UserRequestObserver < Mongoid::Observer
  def before_save user_request
    if user_request.status_changed? && user_request.status == 'resolved'
      user_request.resolved_at = Time.now
    end
  end

  def after_create user_request
    if user_request.status == 'pending'
      user = user_request.user
      project_unit = user_request.project_unit

      if user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "#{user_request.request_type}_request_created").id,
          recipients: [user],
          cc_recipients: (user.channel_partner_id.present? ? [user.channel_partner] : []),
          triggered_by_id: user_request.id,
          triggered_by_type: user_request.class.to_s
        })
      end

      if project_unit.present? && user.booking_portal_client.sms_enabled?
        template = SmsTemplate.where(name: "#{user_request.request_type}_request_created").first
        if template.present?
          Sms.create!(
            booking_portal_client_id: user.booking_portal_client_id,
            recipient_id: user.id,
            sms_template_id: template.id,
            triggered_by_id: user_request.id,
            triggered_by_type: user_request.class.to_s,
          )
        end
      end
    end
  end

  def after_update user_request
    if user_request.status_changed? && user_request.status == 'resolved'
      if user_request.request_type == "cancellation"
        if user_request.project_unit.present? && (user_request.request_type == "cancellation") && ["blocked", "booked_tentative", "booked_confirmed"].include?(user_request.project_unit.status)
          project_unit = user_request.project_unit
          project_unit.processing_user_request = true
          project_unit.make_available
          project_unit.save(validate: false)
        end
      elsif user_request.status_changed? && user_request.status == 'resolved' && user_request.request_type == "swap"
        ProjectUnitSwapService.new(user_request.project_unit_id, user_request.alternate_project_unit_id).swap
      end

      if user_request.user.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: user_request.user.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "#{user_request.request_type}_request_#{user_request.status}").id,
          recipients: [user_request.user],
          cc_recipients: (user_request.user.channel_partner_id.present? ? [user_request.user.channel_partner] : []),
          triggered_by_id: user_request.id,
          triggered_by_type: user_request.class.to_s
        })
      end

      template = SmsTemplate.where(name: "#{user_request.request_type}_request_resolved").first
      if template.present? && user_request.user.booking_portal_client.sms_enabled?
        receipt = user_request.receipt
        Sms.create!(
          booking_portal_client_id: user_request.user.booking_portal_client_id,
          recipient_id: user_request.user_id,
          sms_template_id: template.id,
          triggered_by_id: receipt.id,
          triggered_by_type: receipt.class.to_s
        )
      end
    end
  end
end
