module Gamification
  include ApplicationHelper
  DEFAULT_CHANNEL = "gamification"
  DEFAULT_EVENT = "update"

  class PushNotification
    require 'pusher'

    def initialize
      @pusher_client = Pusher::Client.new(
        app_id: ENV_CONFIG[:pusher]['pusher_api_app_id'],
        key: ENV_CONFIG[:pusher]['pusher_api_key'],
        secret: ENV_CONFIG[:pusher]['pusher_api_secret'],
        cluster: ENV_CONFIG[:pusher]['pusher_api_cluster'],
        encrypted: true
      )
    end

    def push(message="", channel=nil, event=nil)
      if channel.blank?
        channel = DEFAULT_CHANNEL
      end
      if event.blank?
        event = DEFAULT_EVENT
      end
      message = message.to_s
      if message.present?
        @pusher_client.trigger(channel, event, {
          message: message
        })
      end
    end
  end

  class Job
    def execute
      count = BookingDetail.ne(status: "cancelled").count
      if count > 4
        booking_detail = BookingDetail.ne(status: "cancelled").offset(rand(count)).first
        booking_detail.send_notification! if booking_detail.present?
      else
        message = "#{['Kavitha', 'Murthy', 'Dr. Rahul', 'Supriya', 'Kiran', 'Ganesh'].sample} from #{['Bengaluru', 'Bangalore', 'Bengaluru', 'Mysore', 'Hyderabad', 'Mumbai', 'Coimbatore', 'Chennai', 'Kochi'].sample} just booked an apartment in #{ProjectTower.in(id: ProjectUnit.where(status: 'available').distinct(:project_tower_id)).distinct(:name).sample}"
        Gamification::PushNotification.new.push(message)
      end
    end
  end
end
