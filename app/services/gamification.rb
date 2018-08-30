module Gamification
  DEFAULT_CHANNEL = "gamification"
  DEFAULT_EVENT = "update"

  class Base
    include ApplicationHelper
    def dashboard_data
      messages = []
      if current_client.enable_actual_inventory?
        random_starter = [11, 12, 15, 14, 18, 13, 12, 17, 16, 15, 11, 12]
        messages << "#{BookingDetail.where(created_at: {"$gte": Time.now.beginning_of_day}).count + random_starter[0]} people have paid the token amount today"

        data = ProjectUnit.collection.aggregate([{
          "$match": {
            status: {
              "$in": ['blocked', 'booked_tentative', 'booked_confirmed']
            }
          }
        },{
          "$group": {
            "_id": {
              bedrooms: "$bedrooms",
            },
            count: {
              "$sum": 1
            }
          }
        },{
          "$sort": {
            "_id.bedrooms": 1
          }
        }]).to_a
        data.each_with_index do |d, index|
          messages << "#{random_starter[index+1] + d["count"]} #{d["_id"]["bedrooms"]} BHK Apartments Already Sold"
        end
      end
      messages
    end
  end

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
        message = "#{['Vinayak', 'Tejas', 'Dr. Rahul', 'Supriya', 'Kiran', 'Ganesh', 'Ravi', 'Neha', 'Swati'].sample} from #{['Pune', 'Mumbai', 'Pune', 'Kolhapur', 'Aurangabad', 'Mumbai', 'Dubai', 'Singapore', 'Pune', 'San Francisco'].sample} just booked an apartment in #{ProjectTower.in(id: ProjectUnit.where(status: 'available').distinct(:project_tower_id)).distinct(:name).sample}"
        Gamification::PushNotification.new.push(message) if Rails.env.staging? || Rails.env.production?
      end
    end
  end
end
