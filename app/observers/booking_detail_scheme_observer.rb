class BookingDetailSchemeObserver < Mongoid::Observer
  def before_validation(booking_detail_scheme)
    if booking_detail_scheme.booking_detail.present?
      booking_detail_scheme.project_unit_id = booking_detail_scheme.booking_detail.project_unit_id if booking_detail_scheme.project_unit_id.blank? || booking_detail_scheme.booking_detail_id_changed?
      booking_detail_scheme.project_id = booking_detail_scheme.booking_detail.project_id if booking_detail_scheme.project_id.blank? || booking_detail_scheme.booking_detail_id_changed?
      booking_detail_scheme.user_id = booking_detail_scheme.booking_detail.user_id if booking_detail_scheme.user_id.blank? || booking_detail_scheme.booking_detail_id_changed?
      booking_detail_scheme.lead_id = booking_detail_scheme.booking_detail.lead_id if booking_detail_scheme.lead_id.blank? || booking_detail_scheme.booking_detail_id_changed?
    end
  end

  def after_create(booking_detail_scheme)
    # if booking_detail_scheme.project_unit.status == 'negotiation_failed'
    #   project_unit = booking_detail_scheme.project_unit
    #   project_unit.status = 'under_negotiation'
    #   project_unit.save!
    # end
  end
  def before_save (booking_detail_scheme)
    if booking_detail_scheme.derived_from_scheme_id_was != nil && booking_detail_scheme.derived_from_scheme_id_changed?
      booking_detail_scheme.payment_schedule_template_id = booking_detail_scheme.derived_from_scheme.payment_schedule_template.id
      booking_detail_scheme.cost_sheet_template_id = booking_detail_scheme.derived_from_scheme.cost_sheet_template.id

      attrs = []
      booking_detail_scheme.payment_adjustments.destroy_all
      booking_detail_scheme.derived_from_scheme.payment_adjustments.each do |adjustment|
        new_adjustment  = adjustment.dup
        new_adjustment.editable = false
        booking_detail_scheme.payment_adjustments << new_adjustment
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
  end
end
