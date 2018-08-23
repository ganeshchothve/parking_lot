class DiscountObserver < Mongoid::Observer
  def before_save discount
    if discount.status_changed? && discount.status == 'approved'
      discount.approved_at = Time.now
    end
  end

  def after_save discount
    if discount.status_changed?
      case discount.status
      when 'draft'
        Email.create!({
          booking_portal_client_id: discount.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "discount_draft").id,
          cc: [discount.booking_portal_client.notification_email],
          recipients: [discount.created_by],
          triggered_by_id: discount.id,
          triggered_by_type: discount.class.to_s,
        })
      when 'approved'
        Email.create!({
          booking_portal_client_id: discount.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "discount_approved").id,
          cc: [discount.booking_portal_client.notification_email],
          recipients: [discount.created_by],
          triggered_by_id: discount.id,
          triggered_by_type: discount.class.to_s,
        })
      when 'disabled'
        Email.create!({
          booking_portal_client_id: discount.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "discount_disabled").id,
          cc: [discount.booking_portal_client.notification_email],
          recipients: [discount.created_by],
          triggered_by_id: discount.id,
          triggered_by_type: discount.class.to_s,
        })
      end
    end
  end
end
