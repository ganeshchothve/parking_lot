module DailyReports
  class PaymentsReportWorker
    include Sidekiq::Worker
    include ApplicationHelper

    def perform client_id
      return if client_id.blank?
      client = Client.where(id: client_id).first
      if client && client.enable_daily_reports['payments_report']
        # Send daily report email
        filters = {
          status: %w(clearance_pending success),
          created_at: "#{DateTime.current.in_time_zone('Mumbai').beginning_of_day} - #{DateTime.current.in_time_zone('Mumbai')}"
        }
        projects = Project.all
        projects.each do |project|
          filters = filters.merge({ project_id: project.id })
          ::ReceiptExportWorker.new.perform(nil, filters, {daily_report: true})

          # Send daily report sms
          ::Sms.create!(
            project_id: project.id,
            booking_portal_client_id: client.id,
            recipient: User.where(role: 'admin').first,
            to: client.notification_numbers.split(',').map(&:strip).uniq.compact,
            sms_template_id: Template::SmsTemplate.where(project_id: project.id, name: "daily_payments_report", booking_portal_client_id: client.id).first.try(:id),
            triggered_by_id: Receipt.asc(:created_at).last.id,
            triggered_by_type: 'Receipt'
          )
        end
      end
    end
  end
end
