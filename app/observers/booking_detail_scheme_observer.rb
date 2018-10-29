class BookingDetailSchemeObserver < Mongoid::Observer
  def before_validation booking_detail_scheme
    booking_detail_scheme.send(booking_detail_scheme.event) if booking_detail_scheme.event.present?
    booking_detail_scheme.project_unit_id = booking_detail_scheme.booking_detail.project_unit_id
  end

  def before_save booking_detail_scheme
    if booking_detail_scheme.derived_from_scheme_id_changed?
      booking_detail_scheme.payment_schedule_template_id = booking_detail_scheme.derived_from_scheme.payment_schedule_template.id
      booking_detail_scheme.cost_sheet_template_id = booking_detail_scheme.derived_from_scheme.cost_sheet_template.id

      attrs = []
      booking_detail_scheme.payment_adjustments.each do |payment_adjustment|
        attrs << {_id: payment_adjustment.id, _destroy: true} if payment_adjustment.persisted?
      end

      booking_detail_scheme.assign_attributes({payment_adjustments_attributes: attrs})

      booking_detail_scheme.derived_from_scheme.payment_adjustments.each do |adjustment|
        booking_detail_scheme.payment_adjustments.new({
          name: adjustment.name,
          field: adjustment.field,
          formula: adjustment.formula,
          absolute_value: adjustment.absolute_value,
          editable: false
        })
      end
    end
  end

  def after_save booking_detail_scheme
    project_unit = booking_detail_scheme.booking_detail.project_unit

    if booking_detail_scheme.status_changed? && booking_detail_scheme.status == "approved"
      booking_detail_scheme.booking_detail.booking_detail_schemes.where(status: "approved", id: {"$ne" => booking_detail_scheme.id}).each do |scheme|
        scheme.event = "disabled"
        scheme.save
      end
      project_unit.calculate_agreement_price
      project_unit.save
    end
    if booking_detail_scheme.status_changed?
      if booking_detail_scheme.status == "draft" && booking_detail_scheme.created_by_user
        Email.create!({
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "booking_detail_scheme_draft").id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [booking_detail_scheme.created_by],
          cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
          triggered_by_id: booking_detail_scheme.id,
          triggered_by_type: booking_detail_scheme.class.to_s
        })
      elsif booking_detail_scheme.status == "approved"
        Email.create!({
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "booking_detail_scheme_approved").id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [booking_detail_scheme.created_by, booking_detail_scheme.approved_by],
          cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
          triggered_by_id: booking_detail_scheme.id,
          triggered_by_type: booking_detail_scheme.class.to_s
        })
      end
    end
  end
end
