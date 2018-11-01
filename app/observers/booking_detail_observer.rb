class BookingDetailObserver < Mongoid::Observer
  def after_create booking_detail
    booking_detail.send_notification!

    booking_detail_scheme = booking_detail.project_unit.booking_detail_scheme

    if booking_detail_scheme.present? && booking_detail_scheme.status == "draft"
      booking_detail_scheme.booking_detail_id = booking_detail.id
      if booking_detail_scheme.editable_payment_adjustments.count > 0
        booking_detail_scheme.event = "under_negotiation"
      else
        booking_detail_scheme.event = "approved"
        booking_detail_scheme.approved_by_id = booking_detail.project_unit.user.id
      end
    else
      scheme = booking_detail.project_unit.project_tower.default_scheme

      booking_detail_scheme = BookingDetailScheme.create!(
        derived_from_scheme_id: scheme.id,
        booking_detail_id: booking_detail.id,
        created_by_id: booking_detail.project_unit.user.id,
        booking_portal_client_id: scheme.booking_portal_client_id,
        cost_sheet_template_id: scheme.cost_sheet_template_id,
        payment_schedule_template_id: scheme.payment_schedule_template_id,
        payment_adjustments: scheme.payment_adjustments.collect(&:clone).collect{|record| record.editable = false},
        project_unit_id: booking_detail.project_unit_id
      )
      booking_detail_scheme.event = "approved"
      booking_detail_scheme.approved_by_id = booking_detail.project_unit.user.id
    end
    booking_detail_scheme.save!
  end

  def after_save booking_detail
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)

      if booking_detail.status == "cancelled"

      end
    end
  end
end
