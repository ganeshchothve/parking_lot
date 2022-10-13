class CreateLeadWorker
  include Sidekiq::Worker

  def perform manager_ids, params, user, project, client
    kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url)).first

    manager_ids.each do |manager_id|
      manager = User.where(id: manager_id).first
      if manager.present?
        @lead = Lead.new(
                        first_name: params.dig(:lead, :first_name),
                        last_name: params.dig(:lead, :last_name),
                        email: params.dig(:lead, :email),
                        phone: params.dig(:lead, :phone),
                        booking_portal_client: client,
                        project: project,
                        manager_id: manager.id,
                        user: user
                        )
        if @lead.save
          Crm::Api::ExecuteWorker.new.perform('post', 'Lead', @lead.id, nil, {}, kylas_base.id.to_s) if kylas_base.present?
        end
      end
    end
  end
end