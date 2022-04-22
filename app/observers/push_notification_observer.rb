#
# Class Notification Observer
#
class PushNotificationObserver < Mongoid::Observer
  def before_create notification
    notification.user_notification_tokens = notification.recipient.user_notification_tokens.collect{|x| x.token} if notification.user_notification_tokens.blank? && notification.recipient_id.present?
    if notification.user_notification_tokens.present?
      if notification.notification_template_id.present?
        if notification_template = Template::NotificationTemplate.where(id: notification.notification_template_id).first
          notification.content = notification_template.parsed_content(notification.triggered_by)
          notification.data = notification_template.set_request_payload(notification.triggered_by)
          notification.title = notification_template.parsed_title(notification.triggered_by)
          notification.url = URI.join(base_url, notification_template.parsed_url(notification.triggered_by)).to_s
        end
      else
        notification.content = TemplateParser.parse(notification.content, notification.triggered_by)
        notification.title = TemplateParser.parse(notification.title, notification.triggered_by)
        notification.url = TemplateParser.parse(notification.url, notification.triggered_by)
      end
    end
  end

  def after_create notification
    if notification.booking_portal_client.notification_enabled?
      if Rails.env.production?
        Communication::Notification::NotificationWorker.perform_async(notification.id.to_s)
      else
        Communication::Notification::NotificationWorker.new.perform(notification.id.to_s)
        # notification.set(status: 'sent')
      end
    end
  end

  private

  def protocol
    Rails.application.config.action_mailer.default_url_options[:protocol] || 'http'
  end

  def base_url
    "#{protocol}://#{Rails.application.config.action_mailer.default_url_options[:host]}"
  end

end
