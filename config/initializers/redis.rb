if Rails.env == "production" || Rails.env == "staging"
  REDIS_CONFIG = YAML.load(File.open( "/usr/local/redis.yml" ).read).symbolize_keys
else
  REDIS_CONFIG = YAML.load(File.open( Rails.root.join("config/redis.yml") ).read).symbolize_keys
end
REDIS_CURRENT_CONFIG = REDIS_CONFIG[Rails.env.to_sym].symbolize_keys if REDIS_CONFIG[Rails.env.to_sym]

