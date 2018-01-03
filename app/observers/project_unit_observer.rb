class ProjectUnitObserver < Mongoid::Observer
  def before_save project_unit
    if project_unit.status_changed? && ['available', 'not_available'].include?(project_unit.status)
      project_unit.user_id = nil
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
end
