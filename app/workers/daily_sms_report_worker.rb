class DailySmsReportWorker
  include Sidekiq::Worker
  include ApplicationHelper

  def perform client_id
    return if client_id.blank?
    client = Client.where(id: client_id).first
    if client && client.enable_communication['sms'] && client.notification_numbers.present?
      superadmin = User.all.superadmin.first
      projects = client.projects
      projects.each do |project|
        template = Template::SmsTemplate.where(project_id: project.id, name: "daily_sms_report").first
        if template.present?
          sms = Sms.create!(
            project_id: project.id,
            to: client.notification_numbers.split(","),
            booking_portal_client_id: client.id,
            recipient_id: superadmin.id,
            sms_template_id: template.id,
            triggered_by_id: project.id,
            triggered_by_type: project.class.to_s
          )
        end
      end
    end
  end
end
