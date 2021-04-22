class BookingDetailObserver < Mongoid::Observer

  def before_validation booking_detail
    booking_detail.name = booking_detail.project_unit.name
    booking_detail.project_tower_id = booking_detail.project_unit.project_tower_id if booking_detail.project_tower_id.blank?
    booking_detail.manager_id = booking_detail.lead.manager_id if booking_detail.manager_id.blank? && booking_detail.lead.manager_id.present?
  end

  def before_create booking_detail
    booking_detail.map_tasks
  end

  # TODO:: Need to move in state machine callback
  def after_create booking_detail
    #booking_detail.send_notification!
    if booking_detail.hold?
      booking_detail.project_unit.set(status: 'hold', held_on: DateTime.now)
      ProjectUnitUnholdWorker.perform_in(booking_detail.project_unit.holding_minutes.minutes, booking_detail.project_unit_id.to_s)
    end
    #if booking_detail.project_unit.booking_portal_client.external_api_integration?
    #  Crm::Api::Post.where(resource_class: 'BookingDetail').each do |api|
    #    # api.execute(booking_detail)
    #  end
    #end
  end

  def after_save booking_detail
    booking_detail.calculate_incentive if booking_detail.incentive_eligible? && booking_detail.project_unit.booking_portal_client.incentive_calculation_type?("calculated")
  end
end
