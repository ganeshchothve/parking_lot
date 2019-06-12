
class SchemeObserver < Mongoid::Observer
  def before_validation scheme
    scheme.project_id = scheme.project_tower.project_id
    scheme.send(scheme.event) if scheme.event.present?
    if scheme.payment_schedule_template_id.blank?
      scheme.payment_schedule_template_id = Template::PaymentScheduleTemplate.where(default: true).first.id
    end
    if scheme.cost_sheet_template_id.blank?
      scheme.cost_sheet_template_id = Template::CostSheetTemplate.where(default: true).first.id
    end
  end
  def before_save scheme
    if scheme.status_changed? && scheme.status == 'approved'
      scheme.approved_at = Time.now
    end
  end
  def after_save scheme
    #if scheme.status_changed?
    #  if scheme.status == "draft"
    #    SchemeMailer.send_draft(scheme.id, scheme.created_by.id).deliver
    #  elsif scheme.status == "approved"
    #    SchemeMailer.send_approved(scheme.id).deliver
    #  elsif scheme.status == "disabled"
    #    SchemeMailer.send_disabled(scheme.id).deliver
    #  end
    #end
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
