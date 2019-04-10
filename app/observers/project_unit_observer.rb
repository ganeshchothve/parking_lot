class ProjectUnitObserver < Mongoid::Observer
  def before_validation project_unit
    project_unit.agreement_price = project_unit.calculate_agreement_price.round
    project_unit.all_inclusive_price = project_unit.calculate_all_inclusive_price.round
    if project_unit.agreement_price_changed?
      project_unit.booking_price = (project_unit.agreement_price * project_unit.booking_price_percent_of_agreement_price).round
    end
  end

  def before_save project_unit

    project_unit.blocking_amount = project_unit.booking_portal_client.blocking_amount if project_unit.blocking_amount.blank?

    if project_unit.primary_user_kyc_id.blank? && project_unit.user_kyc_ids.present?
      project_unit.primary_user_kyc_id = project_unit.user_kyc_ids.first
    end
    if project_unit.primary_user_kyc_id.present? && project_unit.user_kyc_ids.present?
      project_unit.user_kyc_ids.reject!{|x| x == project_unit.primary_user_kyc_id}
    end
    # if project_unit.status == 'available'
    #   project_unit.available_for = 'user'
    # end
    # if project_unit.status == 'employee'
    #   project_unit.available_for = 'employee'
    # end
    # if project_unit.status == 'management'
    #   project_unit.available_for = 'management'
    # end
    if project_unit.status_changed? && project_unit.user_id.present?
      SelldoLeadUpdater.perform_async(project_unit.user_id.to_s)
    end
    if project_unit.status_changed? && project_unit.status == 'hold'
      project_unit.held_on = DateTime.now
      ProjectUnitUnholdWorker.perform_in(project_unit.holding_minutes.minutes, project_unit.id.to_s)
    elsif project_unit.status_changed? && project_unit.status != 'hold'
      project_unit.held_on = nil
    end
    if project_unit.status_changed? && ProjectUnit.booking_stages.include?(project_unit.status) && ['available', 'hold'].include?(project_unit.status_was)
      project_unit.blocked_on = Date.today
      project_unit.auto_release_on = project_unit.blocked_on + project_unit.blocking_days.days
    end
    if project_unit.status != 'blocked' && project_unit.status != 'booked_tentative'
      project_unit.auto_release_on = nil
    end
  end

  def after_save project_unit
    BookingDetail.run_sync(project_unit.id, project_unit.changes)
  end

  def after_update project_unit
    user = project_unit.user
    # if project_unit.status_changed? && ProjectUnit.booking_stages.include?(project_unit.status)

    if project_unit.auto_release_on_changed? && project_unit.auto_release_on.present? && project_unit.auto_release_on_was.present?
      if project_unit.booking_portal_client.email_enabled?
        Email.create!({
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id:Template::EmailTemplate.find_by(name: "auto_release_on_extended").id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: project_unit.id,
          triggered_by_type: project_unit.class.to_s
        })
      end
    end
  end
end
