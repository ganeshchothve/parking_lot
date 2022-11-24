class ProjectObserver < Mongoid::Observer
  def before_validation project
    project.disable_project = {walk_ins: false, bookings: false, invoicing: false} if project.disable_project.blank?
    project.disable_project[:walk_ins] = (project.disable_project[:walk_ins].to_s == "true") || (project.disable_project[:walk_ins].to_s == "1")
    project.disable_project[:bookings] = (project.disable_project[:bookings].to_s == "true") || (project.disable_project[:bookings].to_s == "1")
    project.disable_project[:invoicing] = (project.disable_project[:invoicing].to_s == "true") || (project.disable_project[:invoicing].to_s == "1")
  end

  def after_create project
    DatabaseSeeds::EmailTemplates.project_based_email_templates_seed(project.id.to_s)
    DatabaseSeeds::SmsTemplate.project_based_sms_templates_seed(project.id.to_s, project.booking_portal_client_id.to_s)
    DatabaseSeeds::UITemplate.project_based_seed(project.id.to_s, project.booking_portal_client_id.to_s)
    Template::InvoiceTemplate.seed(project.booking_portal_client_id.to_s, project.id.to_s)
    # Email and Sms Templates are disabled by default
    Template.in(_type: ['Template::SmsTemplate', 'Template::EmailTemplate'], project_id: project.id, booking_portal_client_id: project.booking_portal_client_id).update_all(is_active: false)
    Template::CostSheetTemplate.create(name: "Default Cost sheet template", content: Template::CostSheetTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id, default: true)
    Template::PaymentScheduleTemplate.create(name: "Default payment schedule template", content: Template::PaymentScheduleTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, default: true, project_id: project.id)
    Template::ReceiptTemplate.create(content: Template::ReceiptTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id)
    Template::AllotmentLetterTemplate.create(content: Template::AllotmentLetterTemplate.default_content, booking_portal_client_id: project.booking_portal_client_id, project_id: project.id)
    Template::BookingDetailFormTemplate.seed(project.id.to_s, project.booking_portal_client_id.to_s)
    # Create a default token type
    token_type = project.token_types.create(name: 'Default', token_amount: (project.blocking_amount || project.booking_portal_client.blocking_amount), token_prefix: (project.name.gsub(/\s+/, '')[0..2].try(:upcase).presence || 'TKN'), token_seed: 0)
    token_type.init if token_type.valid?
  end
end
