Sidekiq.configure_server do |config|
  config.options[:queues] = %w(default mailers) if Rails.env.development? || Rails.env.test?
  config.redis = ENV_CONFIG[:redis]
end

Sidekiq.configure_client do |config|
  config.redis = ENV_CONFIG[:redis]
end
