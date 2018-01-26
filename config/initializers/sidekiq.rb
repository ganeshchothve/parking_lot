if Rails.env == "production" || Rails.env == "staging"
  SIDEKIQ_CONFIG = YAML.load(File.open( "/usr/local/sidekiq.yml" ).read).symbolize_keys
end
Sidekiq.configure_server do |config|
  config.options[:queues] = %w(default mailers) if Rails.env.development? || Rails.env.test?
  config.redis = REDIS_CURRENT_CONFIG
end

Sidekiq.configure_client do |config|
  config.redis = REDIS_CURRENT_CONFIG
end

