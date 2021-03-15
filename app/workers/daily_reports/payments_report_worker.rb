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

        template = Template::NotificationTemplate.where(name: "daily_payments_report").first
        if template.present? && user.booking_portal_client.notification_enabled?
          push_notification = PushNotification.new(
            notification_template_id: template.id,
            triggered_by_id: Receipt.asc(:created_at).last.id,
            recipient_id: User.where(role: 'admin').first.id,
            booking_portal_client_id: client.id
          )
          push_notification.save
        end
      end
    end
  end
end
