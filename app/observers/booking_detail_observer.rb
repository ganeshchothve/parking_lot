class BookingDetailObserver < Mongoid::Observer
  def before_create(booking_detail)
    booking_detail.name = booking_detail.project_unit.name
  end

  def after_create(booking_detail)
    booking_detail.send_notification!
  end

  # TODO:: Need to move in state machine callback
  def after_create booking_detail
    if current_client.external_api_integration?
      Crm::Api::Post.where(resource_class: 'BookingDetail').each do |api|
        # api.execute(booking_detail)
      end
    end
    if booking_detail.hold?
      booking_detail.project_unit.set(status: 'hold', held_on: DateTime.now)
      ProjectUnitUnholdWorker.perform_in(booking_detail.project_unit.holding_minutes.minutes, booking_detail.project_unit_id.to_s)
    end
  end
end
