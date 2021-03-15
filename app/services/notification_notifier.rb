module NotificationNotifier
  module Base
    def self.send_notification(notification)
      Object.const_get("NotificationNotifier::#{notification.vendor}").send_notification(notification)
    end
  end

  module Firebase
    def self.send_notification(notification)
      begin
        fcm = FCM.new("AAAAfNEnBiE:APA91bEHWiF2vFXrS2xWvln525_VjWbLPWx-onirIjEudgqt8FSzUfgI9TARtMu21bDuWFVphfpvnQ0DsgTO5xpD0Y31JxgLBpS1jQoCnu_xdyV4iIO_xXbDbYTxSFPr7f5hGFOO6t9r")
        registration_ids= notification.user_notification_tokens
        options = { "notification":
              {
                "title": notification.title,
                "body": notification.content,
                "click_action": notification.url
              }
            }
        response = fcm.send(registration_ids, options)
      rescue StandardError => e
        response = e.message
      end
      response
    end
  end

end