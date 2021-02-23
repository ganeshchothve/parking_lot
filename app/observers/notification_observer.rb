#
# Class Notification Observer
#
class NotificationObserver < Mongoid::Observer
  def before_create notification
    notification.user_notification_tokens = notification.recipient.user_notification_tokens.collect{|x| x.token} if notification.user_notification_tokens.blank? && notification.recipient_id.present?
    if notification.user_notification_tokens.present?
      if notification.notification_template_id.present?
        begin
          notification_template = Template::NotificationTemplate.find notification.notification_template_id
          notification.content = notification_template.parsed_content(notification.triggered_by)
        rescue => e
          notification.content = ''
        end
      else
        notification.content = TemplateParser.parse(notification.content, notification.triggered_by)
      end
    end
  end

  def after_create notification
    if notification.booking_portal_client.notification_enabled?
      if Rails.env.production? || Rails.env.staging?
        Communication::Notification::NotificationWorker.perform_async(notification.id.to_s)
      else
        notification.set(status: 'sent')
      end
    end
  end
end
