SecureHeaders::Configuration.default do |config|
  # config.cookies = {
  #   secure: true, # mark all cookies as "Secure"
  #   httponly: true, # mark all cookies as "HttpOnly"
  #   samesite: {
  #     none: true # mark all cookies as SameSite=None
  #   }
  # }
  config.cookies = {
    samesite: {
      none: true # mark all cookies as SameSite=None
    }
  }
  config.csp = SecureHeaders::OPT_OUT
  config.hsts = SecureHeaders::OPT_OUT
  config.x_frame_options = 'ALLOW-FROM https://app-qa.sling-dev.com/, ALLOW-FROM https://kylas.io/'
  config.x_content_type_options = SecureHeaders::OPT_OUT
  config.x_xss_protection = SecureHeaders::OPT_OUT
  config.x_permitted_cross_domain_policies = SecureHeaders::OPT_OUT
end