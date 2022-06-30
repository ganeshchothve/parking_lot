module SiteVisitsHelper
  def allow_reschedule?(site_visit)
    policy([:admin, site_visit]).edit? && policy([:admin, site_visit]).editable_field?('scheduled_on')
  end

  def allow_add_notes?(site_visit)
    policy([:admin, Note.new(notable: site_visit)]).new? && !current_client.launchpad_portal
  end

  def allow_state_change?(site_visit)
    policy([current_user_role_group, site_visit]).change_state? && policy([current_user_role_group, site_visit]).editable_field?('event')
  end

  def allow_approval_state_change?(site_visit)
    policy([current_user_role_group, site_visit]).change_state? && policy([current_user_role_group, site_visit]).editable_field?('approval_event')
  end
end
