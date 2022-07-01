# frozen_string_literal: true

module Kylas
  # For fetch users details
  class UserDetails < BaseServiceFetchDetails
    def api_call_url
      "#{APP_KYLAS_HOST}/v1/users/me"
    end
  end
end
