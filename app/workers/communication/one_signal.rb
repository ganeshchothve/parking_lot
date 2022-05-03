module Communication
  module OneSignal

    class ExternalUserIdUpdateWorker
      include Sidekiq::Worker

      def perform user_id, player_id
        begin
          user = User.where(id: user_id).first
          if user.present?
            request_url = "#{ENV_CONFIG[:onesignal][:base_url]}/api/v1/players/#{player_id}"
            uri = URI(request_url)
            https = Net::HTTP.new(uri.host, uri.port)
            request_payload = {app_id: ENV_CONFIG[:onesignal][:app_id], external_user_id: user.id.to_s}
            request = Net::HTTP::Put.new(uri)
            request["Content-Type"] = "application/json"
            request.body = request_payload.to_json
            https.use_ssl = true
            response = https.request(request)
            api_log = ApiLog.new(request_url: request_url, request: [request_payload], resource: user, response_type: "Hash")
            case response
            when Net::HTTPSuccess
              api_log.status = "Success"
              api_log.response = [(JSON.parse(response.body) rescue {})]
            else
              api_log.status = "Error"
              api_log.response = [(JSON.parse(response.body) rescue {})]
            end
            api_log.save
          end
        rescue StandardError => e
          Rails.logger.error "[ERR] update_onesignal_external_user_id user_id - #{user.id.to_s} #{e.message}"
        end
      end
    end
  end
end