class ProjectUnitObserver < Mongoid::Observer
  def before_save project_unit
    if project_unit.base_price.blank? && project_unit.data_attributes.find{|x| x["n"] == "base_price"}["v"].present?
      project_unit.base_price = project_unit.data_attributes.find{|x| x["n"] == "base_price"}["v"].to_f
    end
    if project_unit.booking_price.blank? && project_unit.base_price.present?
      project_unit.booking_price = project_unit.base_price * ProjectUnit.booking_price_percent_of_base_price
      project_unit.tds_amount = project_unit.base_price * ProjectUnit.tds_amount_percent_of_base_price
    end
    if project_unit.status_changed? && ['available', 'not_available'].include?(project_unit.status)
      project_unit.user_id = nil
    end
    if project_unit.status_changed? && project_unit.status == 'hold'
      ProjectUnitUnholdWorker.perform_in(ProjectUnit.holding_minutes, project_unit.id.to_s)
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

    if project_unit.status_changed?
      project_unit.project_unit_state_changes.create!(changed_on: Time.now, status: project_unit.status, status_was: project_unit.status_was)
    end
  end
end
