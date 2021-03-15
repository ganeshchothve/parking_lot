class ReferralObserver < Mongoid::Observer

  def after_create(referral)
    email = Email.create!({
      booking_portal_client_id: referral.booking_portal_client.id,
      email_template_id: Template::EmailTemplate.find_by(name: "referral_invitation").id,
      to: [referral.email],
      cc: (user.booking_portal_client.notification_email.to_s.split(',').map(&:strip) || []) + [referral.referred_by.email],
      recipients: [referral.referred_by],
      triggered_by_id: referral.id,
      triggered_by_type: referral.class.to_s
    })
    email.sent!

    Sms.create!({
      booking_portal_client_id: referral.booking_portal_client.id,
      recipient: referral.referred_by,
      to: [referral.phone],
      sms_template_id: Template::SmsTemplate.find_by(name: "referral_invitation").id,
      triggered_by_id: referral.id,
      triggered_by_type: referral.class.to_s
    })

    template = Template::NotificationTemplate.where(name: "referral_invitation").first
    if template.present? && user.booking_portal_client.notification_enabled?
      push_notification = PushNotification.new(
        notification_template_id: template.id,
        triggered_by_id: referral.id,
        recipient_id: referral.referred_by.id,
        booking_portal_client_id: referral.user.booking_portal_client.id
      )
      push_notification.save
    end
  end
end
