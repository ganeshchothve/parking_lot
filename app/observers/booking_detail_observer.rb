class BookingDetailObserver < Mongoid::Observer
  def after_create booking_detail
    booking_detail.send_notification!
    scheme = booking_detail.project_unit.scheme
    BookingDetail::Scheme.create!(scheme.clone.merge(booking_detail_id: booking_detail.id))
  end

  def after_save booking_detail
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)

      if booking_detail.status == "cancelled"

      end
    end
  end
end
