source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'mixpanel-ruby'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'razorpay'
gem 'nested_form'
gem 'pusher'
gem 'active_link_to'
gem "font-awesome-sass"
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# ORM for mongodb that supports rails 5
gem 'mongoid', '~> 7.0.2'
# Auto-incrementing Primary key like behavior in Mongoid
gem 'mongoid-autoinc'
# Comprehensive solution for user authentication in rails
gem 'devise'
gem 'active_model_otp'
gem 'simple_token_authentication', '~> 1.0'
# Simple solution for authorization of users
gem 'pundit'
# Background processing
gem 'sidekiq'
# namespacing of various redis-environments in case you are using multiple apps in same redis space
gem 'redis-namespace'
gem "omniauth-google-oauth2"
gem 'omniauth'
# handle nested forms in a better way
gem 'cocoon'
# pagination for mongoid document based records
gem 'will_paginate_mongoid'
# observer support for mongoid. Used for callback based code.
gem 'mongoid-observers', '~> 0.3.0'
gem 'rails-observers',  github: 'rails/rails-observers'
# for file upload
gem 'fog-aws'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'

# for simplified HTTP requests
gem 'httparty', '>= 0.14.0'
# for creating and modifying spreadsheets / excel / CSVs
gem 'spreadsheet', '>= 1.1.4'
gem "roo", "~> 2.7.0"
gem 'whenever', :require => false

gem 'sprockets-rails', '>= 2.3.2' # force this version for bootstrap 4 gem
# Bootstrap lib gem for rails. #TODO: upgrade this when B4 is out of beta
gem 'bootstrap'
gem 'jquery-rails'
gem 'rest-client'

# phone numbers on users -> model & validation
gem 'phonelib'
# generate pdf
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'bootstrap-email'
gem 'mongoid-sadstory', '~> 0.0.2'

# TODO: run this command on server before deployment on a new server
# TO GET TOKEN: curl -u 'username' -d '{"scopes":["repo"],"note": "Audit app by Sell.Do"}' https://api.github.com/authorizations
# bundle config GITHUB__COM <YOUR TOKEN>:x-oauth-basic
gem 'audit', git: 'https://github.com/amuratech/audit.git'

gem 'aasm'
gem 'mailgun-ruby'
gem 'safe_parser'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'

  # handy console for finding source-code, debugging, pretty printing, etc
  gem 'pry-rails'
  # gives the documentation for standard ruby libary in pry
  gem 'pry-doc'
  # parallelize your tests for faster testing
  gem 'parallel_tests'
  gem "premailer"
  gem 'rspec-rails'
  gem 'mongoid-rspec'
  gem 'letter_opener'
end

group :test do
  gem 'faker', github: 'stympy/faker'
  gem 'shoulda', '~> 3.5'
  gem 'shoulda-matchers', '3.1.2'
  gem "factory_bot_rails"
  gem 'rails-controller-testing'
  gem 'rspec-sidekiq'
  gem 'database_cleaner'
  gem 'simplecov', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Deploy on any server using capistrano
  gem 'capistrano'
  # Tailored rails deployments using capistrano
  gem 'capistrano-rails'
  # Restart phusion passenger on deployment
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'
  gem 'capistrano-rvm'
  # code documentation
  gem 'yard'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production, :staging do
  gem 'honeybadger', '~> 3.1'
  gem 'newrelic-redis'
  gem 'newrelic_rpm'
end
gem 'asset_sync', '>= 2.4.0'
gem 'humanize', require: 'humanize'
gem 'request_store'
