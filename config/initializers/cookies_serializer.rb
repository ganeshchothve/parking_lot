# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
Rails.application.config.action_dispatch.cookies_serializer = :json
Rails.application.config.session_store :cookie_store, key: '_app_session', expire_after: nil, domain: :all, tld_length: (ENV_CONFIG[:session_tld_length] || 2)
