class ProjectObserver < Mongoid::Observer
  def after_create project
    DatabaseSeeds::EmailTemplates.project_based_email_templates_seed(project.id.to_s)
    DatabaseSeeds::SmsTemplate.project_based_sms_templates_seed(project.id.to_s, project.booking_portal_client_id.to_s)
    # Email and Sms Templates are disabled by default
    Template.in(_type: ['Template::SmsTemplate', 'Template::EmailTemplate'], project_id: project.id).update_all(is_active: false)
    Template::CostSheetTemplate.create(name: "Default Cost sheet template", content: Template::CostSheetTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id, default: true)
    Template::PaymentScheduleTemplate.create(name: "Default payment schedule template", content: Template::PaymentScheduleTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, default: true, project_id: project.id)
    Template::ReceiptTemplate.create(content: Template::ReceiptTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id)
    Template::AllotmentLetterTemplate.create(content: Template::AllotmentLetterTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id)
    Template::BookingDetailFormTemplate.seed(project.id.to_s, project.booking_portal_client_id.to_s)
  end
end
