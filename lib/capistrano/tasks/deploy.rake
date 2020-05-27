require 'pathname'
namespace :deploy do
  desc 'Seeds database'
  task :seed do
    on roles(:app) do |server|
      ask(:client_name, nil)
      ask(:project_name, nil)
      ask(:rera_no, nil)

      # Get booking_portal_domains -> IP from ssh server details & domain from env. config file if set.
      set :_domain, `ssh -G #{server.hostname} | awk '/^hostname / { print $2 }'`.strip
      file_path = File.expand_path("../../../../config/deploy/#{fetch(:application)}-#{fetch(:rails_env)}-booking-portal-env.yml", __FILE__)
      if Pathname.new(file_path).exist?
        env_config = (YAML.load(File.open(file_path).read).symbolize_keys)
        set :_host, env_config[:host] unless env_config[:host].to_s.length.zero?
      end
      booking_portal_domains = ""
      booking_portal_domains += "#{fetch(:_domain)}" unless fetch(:_domain).to_s.length.zero?
      booking_portal_domains += ",#{fetch(:_host)}" unless fetch(:_host).to_s.length.zero?

      within release_path do
        execute :bundle, :exec, :"rake db:seed RAILS_ENV=#{fetch(:rails_env)} client_name='#{fetch(:client_name)}' project_name='#{fetch(:project_name)}' rera_no='#{fetch(:rera_no)}' booking_portal_domains='#{booking_portal_domains}'"
      end
    end
  end

  desc 'Uploads required config files'
  task :upload_configs do
    on roles(:all) do
      unless test("[ -f #{deploy_to}/shared/config/lead_conflicts_executers.yml ]")
        upload!(File.expand_path('../../../../config/lead_conflicts_executers.yml.example', __FILE__), shared_path.join('config/lead_conflicts_executers.yml'))
      end
      unless test("[ -f #{deploy_to}/shared/config/sidekiq_manager.yml ]")
        upload!(File.expand_path('../../../../config/sidekiq_manager.yml.example', __FILE__), shared_path.join('config/sidekiq_manager.yml'))
      end
      unless test("[ -f #{deploy_to}/shared/config/generic-booking-portal-env.yml ]")
        upload!(File.expand_path("../../../../config/deploy/#{fetch(:application)}-#{fetch(:rails_env)}-booking-portal-env.yml", __FILE__), shared_path.join('config/generic-booking-portal-env.yml'))
      end
    end
  end

  desc 'Change folder permissions'
  task :change_permissions do
    on roles(:app) do
      within shared_path do
        if test("[ $(stat -c '%a' \"#{shared_path.join('exports')}\" \"#{shared_path.join('tmp')}\" \"#{shared_path.join('log')}\" \"#{shared_path.join('public/uploads')}\" | tr -d '\\n') != \"777777777777\" ]")
          execute :chmod, '-R', '0777', 'exports', 'tmp', 'log', 'public/uploads'
          execute :setfacl, '-Rdm', 'm::rwx', 'exports', 'tmp', 'log', 'public/uploads'
        end
      end
    end
  end

  desc 'Make directory for sidekiq pids'
  task :make_sidekiq_pids_dir do
    on roles(:app) do
      within shared_path do
        unless test("[ -d \"#{shared_path.join('tmp/pids')}\" ]")
          execute :mkdir, 'tmp/pids'
        end
      end
    end
  end
end
