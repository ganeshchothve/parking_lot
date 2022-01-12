Sidekiq.configure_server do |config|
  config.options[:queues] = %w(default mailers event) if Rails.env.development? || Rails.env.test?
  config.redis = ENV_CONFIG[:redis]

  config.server_middleware do |chain|
    chain.add SidekiqLocalizationMiddleware
  end
end

Sidekiq.configure_client do |config|
  config.redis = ENV_CONFIG[:redis]
end

# To enable delayed extensions.
Sidekiq::Extensions.enable_delay!
