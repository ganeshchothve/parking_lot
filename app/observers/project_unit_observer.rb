class ProjectUnitObserver < Mongoid::Observer
  def before_save project_unit
    if project_unit.primary_user_kyc_id.blank? && project_unit.user_kyc_ids.present?
      project_unit.primary_user_kyc_id = project_unit.user_kyc_ids.first
    end
    if project_unit.primary_user_kyc_id.present? && project_unit.user_kyc_ids.present?
      project_unit.user_kyc_ids.reject!{|x| x == project_unit.primary_user_kyc_id}
    end
    if project_unit.status_changed? && ['hold', 'blocked', 'booked_tentative', 'booked_confirmed'].exclude?(project_unit.status)
      project_unit.user_id = nil
      project_unit.applied_discount_rate = 0
      project_unit.applied_discount_id = nil
    end
    project_unit.calculate_agreement_price
    if project_unit.status == 'available'
      project_unit.status = 'employee' if project_unit.available_for == 'employee'
      project_unit.status = 'management' if project_unit.available_for == 'management'
    end
    if project_unit.status_changed? && project_unit.status == 'hold'
      project_unit.held_on = DateTime.now
      project_unit.applied_discount_rate = project_unit.discount_rate(project_unit.user)
      project_unit.applied_discount_id = project_unit.applicable_discount_id(project_unit.user)
      ProjectUnitUnholdWorker.perform_in(ProjectUnit.holding_minutes.minutes, project_unit.id.to_s)
      SelldoLeadUpdater.perform_async(project_unit.user_id.to_s)
      ApplicationLog.log("unit_hold", {
        id: project_unit.id,
        base_rate: project_unit.base_rate,
        discount: project_unit.applied_discount_rate,
        discount_id: project_unit.applied_discount_id
      }, RequestStore.store[:logging])
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
    if project_unit.status_changed? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(project_unit.status_was) && ["available", "employee", "management"].include?(project_unit.status)
      user_was = User.find(project_unit.user_id_was)
      project_unit.set(user_id: nil, blocked_on: nil, auto_release_on: nil, held_on: nil, primary_user_kyc_id: nil, user_kyc_ids: [])
      project_unit.receipts.update_all(project_unit_id: nil, status: "cancelled")

      mailer = ProjectUnitMailer.released(user_was.id.to_s, project_unit.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      message = "Dear #{user_was.name}, you missed out! We regret to inform you that the apartment you shortlisted has been released. Click here if you'd like to re-start the process: #{user_was.dashboard_url} Your cust ref id is #{user_was.lead_id}"
      if Rails.env.development?
        SMSWorker.new.perform(user_was.phone.to_s, message)
      else
        SMSWorker.perform_async(user_was.phone.to_s, message)
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
        SelldoInventoryPusher.perform_async(project_unit.status, project_unit.id.to_s, Time.now.to_i)
        mailer.deliver_later
      end
      user = project_unit.user
      if project_unit.status == "blocked"
        message = "Congratulations #{user.name}, #{project_unit.name} has been Blocked / Tentative Booked for you for the next 7 days! To own the home, you’ll need to pay the pending amount of Rs. #{project_unit.pending_balance} within these 7 days. To complete the payment now, click here: #{user.dashboard_url}"
      elsif project_unit.status == "booked_confirmed"
        message = "Welcome to the Embassy family! You're now the proud owner of #{project_unit.name} at Embassy Edge in Embassy Springs. Our executives will be in touch regarding agreement formalities."
      end
      if Rails.env.development?
        SMSWorker.new.perform(user.phone.to_s, message)
      else
        SMSWorker.perform_async(user.phone.to_s, message)
      end
    end

    if project_unit.auto_release_on_changed? && project_unit.auto_release_on.present? && project_unit.auto_release_on_was.present?
      mailer = ProjectUnitMailer.auto_release_on_extended(project_unit.id.to_s, project_unit.auto_release_on_was.to_s)
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
