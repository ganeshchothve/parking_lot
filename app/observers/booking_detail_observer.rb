class BookingDetailObserver < Mongoid::Observer
  def after_create booking_detail
    booking_detail.send_notification!
    scheme = if booking_detail.project_unit.selected_scheme_id.present?
      Scheme.find(booking_detail.project_unit.selected_scheme_id)
    else
      booking_detail.project_unit.project_tower.default_scheme
    end

    BookingDetailScheme.create!({derived_from_scheme_id: scheme.id, booking_detail_id: booking_detail.id})
    booking_detail.project_unit.set(selected_scheme_id: nil)
  end

  def after_save booking_detail
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)

      if booking_detail.status == "cancelled"

      end
    end
  end
end
