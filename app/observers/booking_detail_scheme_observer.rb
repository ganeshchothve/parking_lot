class BookingDetailSchemeObserver < Mongoid::Observer
  def before_validation(booking_detail_scheme)
    booking_detail_scheme.project_unit_id = booking_detail_scheme.booking_detail.project_unit_id if booking_detail_scheme.project_unit_id.blank?
    booking_detail_scheme.user_id = booking_detail_scheme.booking_detail.user_id if booking_detail_scheme.user_id.blank? && booking_detail_scheme.booking_detail.present?
  end

  def after_create(booking_detail_scheme)
    # if booking_detail_scheme.project_unit.status == 'negotiation_failed'
    #   project_unit = booking_detail_scheme.project_unit
    #   project_unit.status = 'under_negotiation'
    #   project_unit.save!
    # end
  end

  def before_save(booking_detail_scheme)
    if booking_detail_scheme.payment_adjustments.present? && booking_detail_scheme.payment_adjustments.last.new_record?
      booking_detail_scheme.draft 
    end
    if booking_detail_scheme.derived_from_scheme_id_changed?
      booking_detail_scheme.draft
      booking_detail_scheme.payment_schedule_template_id = booking_detail_scheme.derived_from_scheme.payment_schedule_template.id
      booking_detail_scheme.cost_sheet_template_id = booking_detail_scheme.derived_from_scheme.cost_sheet_template.id

      attrs = []
      booking_detail_scheme.payment_adjustments.destroy
      booking_detail_scheme.derived_from_scheme.payment_adjustments.each do |adjustment|
        booking_detail_scheme.payment_adjustments << adjustment.dup
      end
    end
  end

  # def after_update(booking_detail_scheme)
  #   booking_detail_scheme.booking_detail.send("after_#{booking_detail_scheme.booking_detail.status}_event")
  # end

  def after_save(booking_detail_scheme)
     _event = booking_detail_scheme.event
    booking_detail_scheme.event = nil
    booking_detail_scheme.send("#{_event}!") if _event.present?
    project_unit = booking_detail_scheme.project_unit
    if booking_detail_scheme.status_changed? && booking_detail_scheme.status == 'approved' && booking_detail_scheme.booking_detail.present?
      # if booking_detail_scheme.status_was == "under_negotiation"
      #   project_unit = booking_detail_scheme.project_unit
      #   project_unit.process_scheme!
      # end
      booking_detail_scheme.booking_detail.booking_detail_schemes.where(status: 'approved', id: { '$ne' => booking_detail_scheme.id }).each do |scheme|
        scheme.event = 'disabled'
        scheme.save
      end
      project_unit.calculate_agreement_price
      project_unit.save
    end
    if booking_detail_scheme.status_changed?
      if booking_detail_scheme.status == 'draft' && booking_detail_scheme.created_by_user && project_unit.booking_portal_client.email_enabled?
        Email.create!(
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: 'booking_detail_scheme_draft').id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [booking_detail_scheme.created_by],
          cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
          triggered_by_id: booking_detail_scheme.id,
          triggered_by_type: booking_detail_scheme.class.to_s
        )
      elsif booking_detail_scheme.status == 'approved' && project_unit.booking_portal_client.email_enabled?
        begin
          Email.create!(
            booking_portal_client_id: project_unit.booking_portal_client_id,
            email_template_id: Template::EmailTemplate.find_by(name: 'booking_detail_scheme_approved').id,
            cc: [project_unit.booking_portal_client.notification_email],
            recipients: [booking_detail_scheme.created_by, booking_detail_scheme.approved_by],
            cc_recipients: (booking_detail_scheme.created_by.manager_id.present? ? [booking_detail_scheme.created_by.manager] : []),
            triggered_by_id: booking_detail_scheme.id,
            triggered_by_type: booking_detail_scheme.class.to_s
          )
        rescue StandardError
          'booking detail scheme approved by is nil'
        end
      end
    end
  end
end
