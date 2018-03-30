class BookingDetailObserver < Mongoid::Observer
  def after_save booking_detail
    if booking_detail.status_changed?
      booking_detail.booking_detail_status_changes.create!(changed_on: Time.now, status: booking_detail.status, status_was: booking_detail.status_was)
    end
  end
end
