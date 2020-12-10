class ProjectTowerObserver < Mongoid::Observer
  def after_create project_tower
    project = project_tower.project
    cost_sheet_template = Template::CostSheetTemplate.where(booking_portal_client_id: project.booking_portal_client_id, default: true, project_id: project.id ).first
    payment_schedule_template = Template::PaymentScheduleTemplate.where(booking_portal_client_id: project.booking_portal_client_id, default: true, project_id: project.id ).first
    user = User.where(role: "admin").first || User.where(role: 'superadmin').first
    Scheme.create!(name: "Default #{project_tower.name} scheme", cost_sheet_template_id: cost_sheet_template.id, payment_schedule_template_id: payment_schedule_template.id, project_id: project_tower.project_id, project_tower_id: project_tower.id, default: true, created_by: user, booking_portal_client_id: project_tower.project.booking_portal_client_id, status: "approved", approved_by: user, project: project)
  end
end
