class ProjectUnitObserver < Mongoid::Observer
  def before_save project_unit
    if project_unit.user_kyc_ids_changed? && project_unit.user_kyc_ids_was.blank? && project_unit.user_kyc_ids.present?
      project_unit.primary_user_kyc_id = project_unit.user_kyc_ids.first
    end
    if project_unit.agreement_price.blank?
      project_unit.agreement_price = (project_unit.base_rate + project_unit.premium_location_charges + project_unit.floor_rise) * project_unit.saleable
    end
    if project_unit.booking_price.blank? && project_unit.agreement_price.present?
      project_unit.booking_price = project_unit.agreement_price * project_unit.booking_price_percent_of_agreement_price
      project_unit.tds_amount = project_unit.agreement_price * project_unit.tds_amount_percent_of_agreement_price
    end
    if project_unit.status_changed? && ['available', 'not_available'].include?(project_unit.status)
      project_unit.user_id = nil
    end
    if project_unit.status_changed? && project_unit.status == 'hold'
      project_unit.held_on = Time.now
      ProjectUnitUnholdWorker.perform_in(ProjectUnit.holding_minutes.minutes, project_unit.id.to_s)
    elsif project_unit.status_changed? && project_unit.status != 'hold'
      project_unit.held_on = nil
    end
    if project_unit.status_changed? && project_unit.status == 'blocked'
      project_unit.blocked_on = Date.today
      project_unit.auto_release_on = project_unit.blocked_on + project_unit.blocking_days.days
    end
    if project_unit.status != 'blocked' && project_unit.status != 'booked_tentative'
      project_unit.auto_release_on = nil
    end
  end

  def after_save project_unit
    BookingDetail.run_sync(project_unit.id, project_unit.changes)

    if project_unit.status_changed? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(project_unit.status_was) && ["available"].include?(project_unit.status)
      project_unit.set(user_id: nil, blocked_on: nil, auto_release_on: nil, held_on: nil, primary_user_kyc_id: nil, user_kyc_ids: [])
      project_unit.receipts.update_all(project_unit_id: nil, status: "cancelled")

      mailer = ProjectUnitMailer.released(user_id.to_s, unit.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      if Rails.env.development?
        SMSWorker.new.perform("", "")
      else
        SMSWorker.perform_async("", "")
      end
    end

    if (ProjectUnit.sync_trigger_attributes & project_unit.changes.keys).present?
      # TODO: Write to log file
      if project_unit.sync_with_third_party_inventory
        project_unit.sync_with_selldo
      else
        # TODO: send escalation mail to us and third_party_inventory dev team
        # TODO: Let the customer know that their might be some issue and the team will get back via email
        project_unit.status = 'error'
        project_unit.save(validate: false)
      end
    end
  end

  def after_update project_unit
    if project_unit.status_changed? && ['blocked', 'booked_tentative', 'booked_confirmed'].include?(project_unit.status)
      mailer = ProjectUnitMailer.send(project_unit.status, project_unit.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        SelldoPusher.perform_async(project_unit.status, project_unit.id.to_s, Time.now.to_i)
        mailer.deliver_later
      end
      if Rails.env.development?
        SMSWorker.new.perform("", "")
      else
        SMSWorker.perform_async("", "")
      end
    end

    if project_unit.auto_release_on_changed? && project_unit.auto_release_on.present? && project_unit.auto_release_on_was.present?
      mailer = ProjectUnitMailer.auto_release_on_extended(project_unit.id.to_s, project_unit.auto_release_on_was)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      if Rails.env.development?
        SMSWorker.new.perform("", "")
      else
        SMSWorker.perform_async("", "")
      end
    end
  end
end
