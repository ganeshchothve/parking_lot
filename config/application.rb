require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

ENV_CONFIG = (YAML.load(File.open( "config/generic-booking-portal-env.yml" ).read).symbolize_keys).with_indifferent_access

DEVISE_ORM = :mongoid

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BookingPortal
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += ["#{config.root}/app/observers/**/*", "#{config.root}/app/policies/**/*", "#{config.root}/app/services/**/*", "#{config.root}/app/workers/**/*", "#{config.root}/app/uploaders/**/*"]

    config.eager_load_paths << "#{Rails.root}/lib"
    config.mongoid.observers = Dir["#{Rails.root}/app/observers/**/*.rb"].collect{ |f| f.gsub!("#{Rails.root}/app/observers/", "").gsub!(".rb", "")}
    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"
    config.active_job.queue_adapter = :sidekiq
    config.middleware.use(Mongoid::QueryCache::Middleware)
    config.to_prepare do
      Devise::Mailer.layout "mailer"
    end
  end
end
require 'booking_portal'
