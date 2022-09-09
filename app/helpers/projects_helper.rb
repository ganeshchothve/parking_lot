module ProjectsHelper
  def allow_interest_subscription?(project)
    interested_project = InterestedProject.new(user:current_user, project: project)
    policy([current_user_role_group, interested_project]).create?
  end

  def allow_walkins?(project)
    policy([:admin, Lead.new(project_id: project.id)]).new?
  end

  def allow_booking_without_inventory?(project, lead)
    policy([current_user_role_group, BookingDetail.new(project: project, user: lead.user, lead: lead)]).show_add_booking_link?
  end

  def allow_invoice_create?(project)
    policy([current_user_role_group, Invoice.new(project: project)]).new?
  end

  def booking_custom_templates(project)
    booking_custom_templates = ::Template::CustomTemplate.where(project_id: project.id, subject_class: 'BookingDetail', is_active: true).pluck(:name, :id)
    booking_custom_templates
  end

end
