# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

# set :application, "booking_portal"
# set :repo_url, "git@github.com:amuratech/booking_portal.git"

# Default branch is :master
# set :branch, "generic"

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/generic"
# set :ssh_options, {forward_agent: true, keepalive: true}

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_files, 'config/lead_conflicts_executers.yml', 'config/sidekiq_manager.yml'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, %w{log tmp vendor/bundle public/uploads exports}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
set :passenger_restart_with_touch, true

namespace :deploy do
  desc 'Seeds database'
  task :seed do
    on roles(:app) do |server|
      ask(:client_name, nil)
      ask(:project_name, nil)
      ask(:rera_no, nil)
      set :booking_portal_domain, `ssh -G #{server.hostname} | awk '/^hostname / { print $2 }'`.strip
      within release_path do
        execute :bundle, :exec, :"rake db:seed RAILS_ENV=#{fetch(:rails_env)} client_name='#{fetch(:client_name)}' project_name='#{fetch(:project_name)}' rera_no='#{fetch(:rera_no)}' booking_portal_domains='#{fetch(:booking_portal_domain)}'"
      end
    end
  end

  desc 'Uploads required config files'
  task :upload_configs do
    on roles(:all) do
      unless test("[ -f #{deploy_to}/shared/config/lead_conflicts_executers.yml ]")
        upload!(File.expand_path('../lead_conflicts_executers.yml.example', __FILE__), "#{deploy_to}/shared/config/lead_conflicts_executers.yml")
      end
      unless test("[ -f #{deploy_to}/shared/config/sidekiq_manager.yml ]")
        upload!(File.expand_path('../sidekiq_manager.yml.example', __FILE__), "#{deploy_to}/shared/config/sidekiq_manager.yml")
      end
      unless test("[ -f #{deploy_to}/shared/config/generic-booking-portal-env.yml ]")
        upload!(File.expand_path("../deploy/#{fetch(:application)}-booking-portal-env.yml", __FILE__), "#{deploy_to}/shared/config/generic-booking-portal-env.yml")
      end
    end
  end

  desc 'Change folder permissions'
  task :change_permissions do
    on roles(:app) do
      within release_path do
        if test("[ $(stat -c '%a' \"#{deploy_to}/shared/exports\" \"#{deploy_to}/shared/tmp\" \"#{deploy_to}/shared/log\" \"#{deploy_to}/shared/public/uploads\" | tr -d '\\n') != \"777777777777\" ]")
          execute :chmod, '-R', '0777', "#{deploy_to}/shared/exports", "#{deploy_to}/shared/tmp", "#{deploy_to}/shared/log", "#{deploy_to}/shared/public/uploads"
        end
      end
    end
  end

  before 'deploy:check:linked_files', 'deploy:upload_configs'
  after :finished, 'deploy:change_permissions'
  #after :finished, 'deploy:seed'
end
