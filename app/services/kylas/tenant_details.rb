# frozen_string_literal: true

module Kylas
  # For fetch tenants details
  class TenantDetails < BaseServiceFetchDetails
    def api_call_url
      "#{APP_KYLAS_HOST}/v1/tenants"
    end
  end
end
