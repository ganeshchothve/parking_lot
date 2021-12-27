class BookingDetailObserver < Mongoid::Observer

  def before_validation booking_detail
    if booking_detail.project_unit.present?
      booking_detail.name = booking_detail.project_unit.name
      booking_detail.project_tower_id = booking_detail.project_unit.project_tower_id if booking_detail.project_tower_id.blank?
    else
      booking_detail.name = booking_detail.booking_project_unit_name
    end
    booking_detail.manager_id = booking_detail.lead&.manager_id if booking_detail.lead.manager && (booking_detail.manager_id.blank? || booking_detail.manager_id_changed?)
    booking_detail.channel_partner_id = booking_detail.manager&.channel_partner_id if booking_detail.manager && (booking_detail.channel_partner_id.blank? ||  booking_detail.manager_id_changed?)
    booking_detail.cp_manager_id = booking_detail.channel_partner&.manager_id if booking_detail.channel_partner && (booking_detail.cp_manager_id.blank? || booking_detail.manager_id_changed?)
    booking_detail.cp_admin_id = booking_detail.cp_manager&.manager_id if booking_detail.cp_manager && (booking_detail.cp_admin_id.blank? || booking_detail.manager_id_changed?) 
  end

  def before_create booking_detail
    booking_detail.map_tasks
  end

  # TODO:: Need to move in state machine callback
  def after_create booking_detail
    #booking_detail.send_notification!
    if booking_detail.project_unit.present? && booking_detail.hold?
      booking_detail.project_unit.set(status: 'hold', held_on: DateTime.now)
      ProjectUnitUnholdWorker.perform_in(booking_detail.project_unit.holding_minutes.minutes, booking_detail.project_unit_id.to_s)
    end
    #if booking_detail.project_unit.booking_portal_client.external_api_integration?
    #  Crm::Api::Post.where(resource_class: 'BookingDetail').each do |api|
    #    # api.execute(booking_detail)
    #  end
    #end
  end

  def before_save booking_detail
    if booking_detail.primary_user_kyc_id.blank? && booking_detail.user_kyc_ids.present?
      booking_detail.primary_user_kyc_id = booking_detail.user_kyc_ids.first
    end
    if booking_detail.primary_user_kyc_id.present? && booking_detail.user_kyc_ids.present?
      booking_detail.user_kyc_ids.reject!{|x| x == booking_detail.primary_user_kyc_id}
    end
  end

  def after_save booking_detail
    booking_detail.calculate_incentive if booking_detail.project_unit.present? && booking_detail.project.present? && booking_detail.incentive_eligible? && booking_detail.project.incentive_calculation_type?("calculated")
  end
end
