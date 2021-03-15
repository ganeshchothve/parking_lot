class DailySmsReportWorker
  include Sidekiq::Worker
  include ApplicationHelper

  def perform
    if current_client.enable_communication['sms'] && current_client.notification_numbers.present?
      record = Client.first
      superadmin = User.where(role: "superadmin").first
      template = Template::SmsTemplate.find_by(name: "daily_sms_report")
      sms = Sms.create!(
        to: record.notification_numbers.split(","),
        booking_portal_client_id: record.id,
        recipient_id: superadmin.id,
        sms_template_id: template.id,
        triggered_by_id: record.id,
        triggered_by_type: record.class.to_s
      )

      template = Template::NotificationTemplate.where(name: "daily_sms_report").first
      if template.present? && user.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: record.id,
          recipient_id: superadmin.id,
          booking_portal_client_id: record.id
        )
        push_notification.save
      end
    end
  end
end
