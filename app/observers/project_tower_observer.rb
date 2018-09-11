class ProjectTowerObserver < Mongoid::Observer
  def after_create project_tower
    cost_sheet_template = Template::CostSheetTemplate.where(booking_portal_client_id: project.booking_portal_client_id, default: true)
    payment_schedule_template = Template::PaymentScheduleTemplate.where(booking_portal_client_id: project.booking_portal_client_id, default: true)
    Scheme.create(name: "Default scheme", cost_sheet_template_id: cost_sheet_template.id, payment_schedule_template_id: payment_schedule_template.id, project_id: project_tower.project_id, project_tower_id: project_tower.id, default: true)
  end
end
