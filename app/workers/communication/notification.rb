#
# Notification worker for communication
#
require 'net/http'
require 'rexml/document'
module Communication
  module Notification
    class NotificationWorker
      include Sidekiq::Worker

      def perform notification_id
        notification = ::PushNotification.find notification_id
        if %w[staging production].include?(Rails.env)
          resp = NotificationNotifier::Base.send_notification(notification)
          notification.sent_on = DateTime.now
          notification.status = resp[:response]
          notification.response = resp
          notification.save
        end
      end
    end
  end
end
