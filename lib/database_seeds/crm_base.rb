module DatabaseSeeds
    module CrmBase
      class Kylas
        def self.seed client_id
          client = Client.where(id: client_id).first
          if client
            crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: client.id).first
            user = User.where(booking_portal_client_id: client.id, role: 'admin').first
            crm_base = Crm::Base.create(domain: ENV_CONFIG.dig(:kylas, :base_url), name: 'Kylas', oauth2_authentication: true, oauth_type: 'kylas', booking_portal_client_id: client.id, user: user) if crm_base.blank? && user.present?
            crm_base.generate_api_key!
          end
        end
      end
    end
end