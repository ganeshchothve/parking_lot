class ChannelPartnerObserverWorker
  include Sidekiq::Worker
    sidekiq_options queue: 'event'

  def perform(channel_partner_id, changes={})
    channel_partner = ChannelPartner.where(id: channel_partner_id).first
    if channel_partner.present?
      interakt_base = Crm::Base.where(domain: ENV_CONFIG.dig(:interakt, :base_url)).first
      selldo_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      onesignal_base = Crm::Base.where(domain: ENV_CONFIG.dig(:onesignal, :base_url)).first

      # For calling Selldo APIs
      if selldo_base
        if (changed_keys = (changes.keys & %w(manager_id interested_services regions company_name)).presence) && changed_keys&.all? {|key| channel_partner[key].present?}
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, nil, changes, selldo_base.id.to_s)
          end
        end
      end

      # For calling Interakt APIs
      if interakt_base
        # Push changes on User
        if (changed_keys = (changes.keys & %w(company_name company_type interested_services manager_id developers_worked_for pan_number rera_id gstin_number regions status)).presence) && changed_keys.all? {|key| channel_partner[key].present?}
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, nil, changes, interakt_base.id.to_s)
          end
        end

        # Push events based on changed attributes
        if changes.has_key?('status') && channel_partner.status.present?
          # Push Registered New Company event on primary cp owner when new channel partner company created.
          if changes.dig('status', 0) == nil && changes.dig('status', 1) == 'inactive'
            payload = {
              'channel_partner' => channel_partner.as_json(include: {primary_user: {methods: [:name]}, manager: {methods: [:name]}})
            }.merge(changes || {})
            Crm::Api::ExecuteWorker.perform_async('post', 'User', channel_partner.primary_user_id, 'Registered New Company', payload, interakt_base.id.to_s)
          end

          # Push company state change event on all channel_partner/cp_owner users
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Company Onboarding State Change', changes, interakt_base.id.to_s)
          end
        end
        if changes.has_key?('manager_id') && channel_partner.manager_id.present?
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Manager Changed', changes, interakt_base.id.to_s)
          end
        end
        if changes.has_key?('regions') && channel_partner.regions.present?
          regions_added = changes['regions'][1] - changes['regions'][0]
          regions_removed = changes['regions'][0] - changes['regions'][1]
          if regions_removed.present?
            regions_removed.each do |region|
              channel_partner.users.each do |cp_user|
                Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Region Removed', {'region_removed' => region}, interakt_base.id.to_s)
              end
            end
          end
          if regions_added.present?
            regions_added.each do |region|
              channel_partner.users.each do |cp_user|
                Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Region Added', {'region_added' => region}, interakt_base.id.to_s)
              end
            end
          end
        end
      end # if interakt_base

      if onesignal_base
        # Push changes on User
        if (changed_keys = (changes.keys & %w(company_name company_type interested_services manager_id developers_worked_for pan_number rera_id gstin_number regions status)).presence) && changed_keys.all? {|key| channel_partner[key].present?}
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, nil, changes, onesignal_base.id.to_s)
          end
        end

        # Push events based on changed attributes
        if changes.has_key?('status') && channel_partner.status.present?
          # Push Registered New Company event on primary cp owner when new channel partner company created.
          if changes.dig('status', 0) == nil && changes.dig('status', 1) == 'inactive'
            payload = {
              'channel_partner' => channel_partner.as_json(include: {primary_user: {methods: [:name]}, manager: {methods: [:name]}})
            }.merge(changes || {})
            Crm::Api::ExecuteWorker.perform_async('put', 'User', channel_partner.primary_user_id, 'Registered New Company', payload, onesignal_base.id.to_s)
          end

          # Push company state change event on all channel_partner/cp_owner users
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, 'Company Onboarding State Change', changes, onesignal_base.id.to_s)
          end
        end
        if changes.has_key?('manager_id') && channel_partner.manager_id.present?
          channel_partner.users.each do |cp_user|
            Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, 'Manager Changed', changes, onesignal_base.id.to_s)
          end
        end
        if changes.has_key?('regions') && channel_partner.regions.present?
          regions_added = changes['regions'][1] - changes['regions'][0]
          regions_removed = changes['regions'][0] - changes['regions'][1]
          if regions_removed.present?
            regions_removed.each do |region|
              channel_partner.users.each do |cp_user|
                Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, 'Region Removed', {'region_removed' => region}, onesignal_base.id.to_s)
              end
            end
          end
          if regions_added.present?
            regions_added.each do |region|
              channel_partner.users.each do |cp_user|
                Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, 'Region Added', {'region_added' => region}, onesignal_base.id.to_s)
              end
            end
          end
        end
      end

    end
  end
end
