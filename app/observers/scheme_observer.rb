class SchemeObserver < Mongoid::Observer
  def before_save scheme
    if scheme.status_changed? && scheme.status == 'approved'
      scheme.approved_at = Time.now
    end
  end

  def after_save scheme
    if scheme.status_changed? && scheme.booking_portal_client.email_enabled?
      # case scheme.status
      # when 'draft'
      #   Email.create!({
      #     booking_portal_client_id: scheme.booking_portal_client_id,
      #     email_template_id:Template::EmailTemplate.find_by(name: "scheme_draft").id,
      #     cc: [scheme.booking_portal_client.notification_email],
      #     recipients: [scheme.created_by],
      #     triggered_by_id: scheme.id,
      #     triggered_by_type: scheme.class.to_s,
      #   })
      # when 'approved'
      #   Email.create!({
      #     booking_portal_client_id: scheme.booking_portal_client_id,
      #     email_template_id:Template::EmailTemplate.find_by(name: "scheme_approved").id,
      #     cc: [scheme.booking_portal_client.notification_email],
      #     recipients: [scheme.created_by],
      #     triggered_by_id: scheme.id,
      #     triggered_by_type: scheme.class.to_s,
      #   })
      # when 'disabled'
      #   Email.create!({
      #     booking_portal_client_id: scheme.booking_portal_client_id,
      #     email_template_id:Template::EmailTemplate.find_by(name: "scheme_disabled").id,
      #     cc: [scheme.booking_portal_client.notification_email],
      #     recipients: [scheme.created_by],
      #     triggered_by_id: scheme.id,
      #     triggered_by_type: scheme.class.to_s,
      #   })
      # end
    end
  end
end
