class BookingDetailObserver < Mongoid::Observer
  def after_create booking_detail
    booking_detail.send_notification!
  end

  def after_save booking_detail
    if booking_detail.status_changed?
      booking_detail.booking_detail_status_changes.create!(changed_on: Time.now, status: booking_detail.status, status_was: booking_detail.status_was)
      if booking_detail.status == "cancelled"
        # Push data to SFDC when unit is cancelled by user - closed_lost unit
        SFDC::ProjectUnitPusher.execute(self.project_unit, { cancellation_request: true, user_id: booking_detail.user_id, primary_user_kyc_id: booking_detail.primary_user_kyc_id })
      end
    end
  end
end
