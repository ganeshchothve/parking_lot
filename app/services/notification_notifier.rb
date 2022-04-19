module NotificationNotifier
  module Base
    def self.send_notification(notification)
      Object.const_get("NotificationNotifier::#{notification.vendor}").send_notification(notification)
    end
  end

  module Firebase
    extend ApplicationHelper
    def self.send_notification(notification)
      begin
        fcm = FCM.new(current_client.notification_api_key)
        if notification.role.present?
          response = send_to_topic(fcm, notification)
        else
          response = send_to_registration_id(fcm, notification)
        end
      rescue StandardError => e
        response = e.message
      end
      response
    end

    def self.send_to_registration_id(fcm, notification)
      registration_ids= notification.user_notification_tokens
      options = { "notification":
            {
              "title": notification.title,
              "body": notification.content,
              "click_action": notification.url
            }
          }
      fcm.send(registration_ids, options)
    end

    def self.send_to_topic(fcm, notification)
      notification_key = "/topics/#{current_client.id}-#{current_project.id}-#{notification.role}"
      _request_header = {"Content-Type": "application/json", "Authorization": "key=#{fcm.api_key}"}
      params = {to: notification_key, notification: {title: notification.title, body: notification.content}}
      uri = URI.join('https://fcm.googleapis.com' ,'/fcm/send')
      Net::HTTP.post(uri, params.to_json, _request_header)
    end
  end

  module OneSignal
    extend ApplicationHelper
    def self.send_notification(notification)
      begin
        fcm = FCM.new(current_client.notification_api_key)
        if notification.role.present?
          response = send_to_topic(fcm, notification)
        else
          response = send_to_registration_id(fcm, notification)
        end
      rescue StandardError => e
        response = e.message
      end
      response
    end

    def self.send_to_registration_id(fcm, notification)
      registration_ids= notification.user_notification_tokens
      options = { "notification":
            {
              "title": notification.title,
              "body": notification.content,
              "click_action": notification.url
            }
          }
      fcm.send(registration_ids, options)
    end

    def self.send_to_topic(fcm, notification)
      notification_key = "/topics/#{current_client.id}-#{current_project.id}-#{notification.role}"
      _request_header = {"Content-Type": "application/json", "Authorization": "key=#{fcm.api_key}"}
      params = {to: notification_key, notification: {title: notification.title, body: notification.content}}
      uri = URI.join('https://fcm.googleapis.com' ,'/fcm/send')
      Net::HTTP.post(uri, params.to_json, _request_header)
    end
  end

end