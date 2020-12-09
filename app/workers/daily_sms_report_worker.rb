class DailySmsReportWorker
  include Sidekiq::Worker
  include ApplicationHelper

  def perform
    if current_client.enable_communication['sms'] && current_client.notification_numbers.present?
      record = Client.first
      superadmin = User.where(role: "superadmin").first
      projects = record.projects
      projects.each do |project|
        template = Template::SmsTemplate.where(project_id: project.id, name: "daily_sms_report").first
        if template.present?
          sms = Sms.create!(
            project_id: project.id,
            to: record.notification_numbers.split(","),
            booking_portal_client_id: record.id,
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
