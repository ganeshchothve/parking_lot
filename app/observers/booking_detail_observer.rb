class BookingDetailObserver < Mongoid::Observer
  def before_create(booking_detail)
    booking_detail.name = "#{booking_detail.project_unit.name}  (#{booking_detail.project_unit.blocked_on})"
  end

  def after_create(booking_detail)
    booking_detail.send_notification!
  end

  def after_save(booking_detail)
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)
    end
  end
end
