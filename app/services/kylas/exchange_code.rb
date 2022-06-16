# frozen_string_literal: true

module Kylas
  # For fetch access & refresh token from IAM service
  class ExchangeCode < BaseServiceAccessToken
    def api_call_url
      redirect_uri = ENV_CONFIG[:kylas][:redirect_url]
      "#{APP_KYLAS_HOST}/oauth/token?grant_type=authorization_code&code=#{code_or_refresh_token}&redirect_uri=#{redirect_uri}"
    end
  end
end
