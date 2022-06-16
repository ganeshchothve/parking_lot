# frozen_string_literal: true

module Kylas
  # For fetch new access token
  class GetAccessToken < BaseServiceAccessToken
    def api_call_url
      "#{APP_KYLAS_HOST}/oauth/token?grant_type=refresh_token&refresh_token=#{code_or_refresh_token}"
    end
  end
end
