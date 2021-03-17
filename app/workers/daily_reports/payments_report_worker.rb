module DailyReports
  class PaymentsReportWorker
    include Sidekiq::Worker
    include ApplicationHelper

    def perform
      client = current_client
      if client.enable_daily_reports['payments_report']
        # Send daily report email
        filters = {
          status: %w(clearance_pending success),
          created_at: "#{DateTime.current.in_time_zone('Mumbai').beginning_of_day} - #{DateTime.current.in_time_zone('Mumbai')}"
        }
        ::ReceiptExportWorker.new.perform(nil, filters, {daily_report: true})

        # Send daily report sms
        ::Sms.create!(
          booking_portal_client_id: client.id,
          recipient: User.where(role: 'admin').first,
          to: client.notification_numbers.split(',').map(&:strip).uniq.compact,
          sms_template_id: Template::SmsTemplate.find_by(name: "daily_payments_report").id,
          triggered_by_id: Receipt.asc(:created_at).last.id,
          triggered_by_type: 'Receipt'
        )
      end
    end
  end
end
