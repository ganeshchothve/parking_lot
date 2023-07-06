module OmniAuth
  module Strategies
    class Selldo < OmniAuth::Strategies::OAuth2
      option :name, :selldo
      option :client_options, {
        :site => ENV_CONFIG.dig(:oauth, :selldo, :url),
        :authorize_url => "oauth/authorize",
      }

      uid do
        raw_info["_id"]
      end

      info do
        {
          :email => raw_info["email"],
        }
      end
      extra do
        {
          :client_id => raw_info["client_id"],
          :role => raw_info["role"],
          :first_name => raw_info['first_name'],
          :last_name  => raw_info['last_name'],
          :phone => raw_info['phone']

        }
      end

      def raw_info
        @raw_info ||= access_token.get("/client/current_resource_owner.json").parsed
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
