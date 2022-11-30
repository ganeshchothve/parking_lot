class CreateLeadWorker
  include Sidekiq::Worker

  def perform manager_ids, params, user_id, project_id, client_id, lead_data
    kylas_base = Crm::Base.where(booking_portal_client_id: client_id, domain: ENV_CONFIG.dig(:kylas, :base_url)).first
    user = User.where(booking_portal_client_id: client_id, id: user_id).first
    project = Project.where(booking_portal_client_id: client_id, id: project_id).first
    client = Client.where(booking_portal_client_id: client_id, id: client_id).first

    count = 0
    manager_ids.each do |manager_id|
      manager = User.where(booking_portal_client_id: client_id, id: manager_id).first
      if manager.present?
        @lead = Lead.new(
                        first_name: params.dig(:lead, :first_name),
                        last_name: params.dig(:lead, :last_name),
                        email: params.dig(:lead, :email),
                        phone: params.dig(:lead, :phone),
                        booking_portal_client: client,
                        project: project,
                        manager_id: manager.id,
                        user: user,
                        kylas_lead_id: (params[:entityId])
                        )
        if @lead.save
          Crm::Api::ExecuteWorker.new.perform('post', 'Lead', @lead.id, nil, {}, kylas_base.id.to_s) if kylas_base.present?
          if (lead_data['products'].blank? || lead_data['products'].pluck('id').map(&:to_s).exclude?(params.dig(:lead, :kylas_product_id))) && count < 1
              response = Kylas::UpdateLead.new(current_user, @lead.kylas_lead_id, params).call
              count += 1 if response[:success]
          end
        end
      end
    end
  end
end