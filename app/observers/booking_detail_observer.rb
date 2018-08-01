class BookingDetailObserver < Mongoid::Observer
  def after_create booking_detail
    booking_detail.send_notification!
  end

  def after_save booking_detail
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)

      ApplicationLog.log("booking_detail_updated", {
        id: booking_detail.id,
        unit_id: booking_detail.project_unit_id,
        user_id: booking_detail.user_id,
        status: booking_detail.status
      }, RequestStore.store[:logging])

      if booking_detail.status == "cancelled"
        
      end
    end
  end
end
